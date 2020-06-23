using System;
using System.IO;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Configuration;
using System.Collections.Generic;
using System.Net.Http;
using System.Text;
using Newtonsoft.Json;
using Microsoft.Azure.Storage.Blob;

namespace My.Function
{
    public class DeniedOutboundCalls
    {

        private readonly IConfiguration _config;
        private readonly HttpClient _http;
        private readonly IEnumerable<CloudBlobClient> _cloudBlobClients;
        private ILogger Logger { get; set; }
        
        public DeniedOutboundCalls(IConfiguration config, HttpClient http, IEnumerable<CloudBlobClient> cloudBlobClients)
        {
            _config = config;
            _http = http;
            _cloudBlobClients = cloudBlobClients;    

        }

        [FunctionName("DeniedOutboundCalls")]
        public  async Task<IActionResult> Run(
            [HttpTrigger(AuthorizationLevel.Anonymous, "get", Route = null)] HttpRequest req, ILogger logger)
        {            
            Logger = logger;
            Logger.LogInformation("C# HTTP trigger function processed a request.");

            string name = req.Query["name"];

            var result = new Dictionary<string, object>();

            result.Add("Request.Host", req.Host);
            result.Add(
                "Request.HttpContext.Connection.RemoteIpAddress",
                req.HttpContext.Connection.RemoteIpAddress.ToString());
            result.Add(
                "Request.HttpContext.Connection.LocalIpAddress",
                req.HttpContext.Connection.LocalIpAddress.ToString());

            await GetUrls(_http, result, _config);

            await GetBlobs(_cloudBlobClients, result, _config);

            return new JsonResult(result);          
        }

        private async Task GetBlobs(
            IEnumerable<CloudBlobClient> cloudBlobClients,
            Dictionary<string, object> result,
            IConfiguration config)
        {
            string path = config["Blob.Path"];
            if (string.IsNullOrEmpty(path))
            {
                Logger.LogInformation("Configuration setting Blob.Path is not set");
                return;
            }

            foreach (var client in cloudBlobClients)
            {
                try
                {
                    ICloudBlob blob = await client.GetBlobReferenceFromServerAsync(new Uri($"{client.BaseUri}{path}"));

                    using (var stream = new MemoryStream())
                    {
                        await blob.DownloadToStreamAsync(stream);
                        stream.Seek(0, SeekOrigin.Begin);
                        string text = Encoding.UTF8.GetString(stream.ToArray());
                        result.Add(client.BaseUri.ToString(), text);
                    }
                }
                catch (Exception ex)
                {
                    result.Add(
                        client.BaseUri.ToString(),
                        new Dictionary<string, string>
                        {
                            { "Exception.GetType().FullName", ex.GetType().FullName },
                            { "Exception.Message", ex.Message }
                        });
                }
            }
        }

        private async Task GetUrls(HttpClient http, Dictionary<string, object> result, IConfiguration config)
        {
            string urls = config["GetUrls"];
            if (string.IsNullOrEmpty(urls))
            {
                Logger.LogInformation("Configuration setting \"GetUrls\" is not set");
                return;
            }

            foreach (string url in urls.Split(';')) await GetUrl(http, result, new Uri(url));
        }

        private async Task GetUrl(HttpClient http, Dictionary<string, object> result, Uri uri)
        {
            //TODO: reusing HttpClient here is not very efficient?

            var responseResult = new Dictionary<string, object>();
            responseResult.Add("URL", uri.ToString());

            try
            {
                var response = await http.GetAsync(uri);
                responseResult.Add("Response.StatusCode", response.StatusCode);
                responseResult.Add("Response.ReasonPhrase", response.ReasonPhrase);
                responseResult.Add("Response.IsSuccessStatusCode", response.IsSuccessStatusCode);
            }
            catch (Exception ex)
            {
                responseResult.Add("Exception.GetType().FullName", ex.GetType().FullName);
                responseResult.Add("Exception.Message", ex.Message);
            }

            result.Add(uri.Host, responseResult);
        }
    }
}
