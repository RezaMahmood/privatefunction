# Introduction

These Azure Functions have the following capabilities:

## PrivateCosmosFunction.cs

- Storage queue trigger on shared storage

- Generate a random identifier

- Store the message on the queue together with random ID to shared CosmosDB collection.

## PrivateFilesFunction.cs

- Blob trigger on shared storage

- Read the contents of the file and for each line

  - Enqueue the line into an EventHub Batch

- Sends the batch of events to EventHub

## DeniedOutboundCalls.cs

Contents kindly donated by Daniel Larsen (dalars) from https://github.com/DanielLarsenNZ/HelloFunctionsDotNetCore - when called, this function should fail if the environment is set up correctly
