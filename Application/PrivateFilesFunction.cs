using System;
using System.IO;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Host;
using Microsoft.Extensions.Logging;
using System.Threading.Tasks;
using System.Text;
using Azure.Messaging.EventHubs;
using Azure.Messaging.EventHubs.Producer;

namespace My.Function
{
    public static class PrivateFilesFunction
    {
        [FunctionName("PrivateFilesFunction")]
        [StorageAccount("SharedStor")]
        public static async Task Run(
            [BlobTrigger("sharedcontainer/{name}")]Stream myBlob,
            string name,
            ILogger log)
        {
            log.LogInformation($"Starting processing of blob\n Name:{name} \n Size: {myBlob.Length} Bytes");

            var eventhubConnection = System.Environment.GetEnvironmentVariable("EventHubConnection");
            var eventHubName = System.Environment.GetEnvironmentVariable("EventHubName");

            await using (var producerClient = new EventHubProducerClient(eventhubConnection, eventHubName))
            {
                int counter = 0;
                using EventDataBatch eventBatch = await producerClient.CreateBatchAsync();

                using (var sr = new StreamReader(myBlob))
                {                   
                    string line = string.Empty;                    
                    while ((line = sr.ReadLine()) != null)
                    {
                        eventBatch.TryAdd(new EventData(Encoding.UTF8.GetBytes(line)));
                        counter++;
                    }
                }

                await producerClient.SendAsync(eventBatch);
                log.LogInformation($"A batch of {counter} messages was sent");
            }

        }


    }
}
