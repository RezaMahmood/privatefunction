using System;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Host;
using Microsoft.Extensions.Logging;

namespace My.Function
{
    public static class PrivateCosmosFunction
    {
        [FunctionName("PrivateCosmosFunction")]
        public static void Run(
            [QueueTrigger("queue", Connection = "SharedStor")]string myQueueItem, 
            [CosmosDB(
                databaseName: "rezadb",
                collectionName: "rezacontainer",
                ConnectionStringSetting = "CosmosDBConnection")]out dynamic document,
            ILogger log)
        {
            var random = new Random();
            var randomId = random.Next(1000).ToString();

            document = new { myData = myQueueItem, id = randomId};
            log.LogInformation($"C# Queue trigger function processed: {myQueueItem}");
        }
    }
}
