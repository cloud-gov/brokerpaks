# Diagrams

## Service Brokers, Before

The current state of service brokers on Cloud.gov. Open Service Broker API requests are sent to the Cloud Foundry API (CAPI). Service brokers are registered with CAPI to handle requests for particular service offerings. CAPI forwards the request to the registered broker, which communicates with AWS to fulfill the request. (For brevity, not all service brokers and AWS APIs currently in use are depicted.)

```mermaid
---
title: "Figure 1: Service Brokers Before Change"
---

flowchart LR
    u["Cloud.gov Customer"]

    subgraph "AWS"

        subgraph "Cloud.gov"
            direction LR
            capi["Cloud Foundry API"]

            subgraph "Service Brokers"
                awsbroker["AWS Broker"]
                s3broker["S3 Broker"]
                extbroker["External Domain Broker"]
            end
        end

        rdsapi["AWS RDS API"]
        s3api["AWS S3 API"]
        route53api["AWS Route 53 API"]
    end

    letsencrypt["Let's Encrypt API"]

    u -->|OSBAPI requests| capi

    capi --> awsbroker
    capi --> s3broker
    capi --> extbroker

    awsbroker --> rdsapi
    s3broker --> s3api
    extbroker --> route53api
    extbroker --> letsencrypt
```

## Service Brokers, After

This change adds a new broker, the Cloud Service Broker (CSB). The CSB uses OpenTofu, an open-source fork of Terraform, to deploy services. The first new service deployed using the CSB will be AWS Simple Email Service (SES).

```mermaid
---
title: "Figure 2: Service Brokers After Change"
---

flowchart LR
    classDef new fill:#ecffec,stroke:#73d893
    u["Cloud.gov Customer"]

    subgraph "AWS"

        subgraph "Cloud.gov"
            direction LR
            capi["Cloud Foundry API"]

            subgraph "Service Brokers"
                awsbroker["AWS Broker"]
                s3broker["S3 Broker"]
                csb["Cloud Service Broker"]:::new
                extbroker["External Domain Broker"]
            end
        end

        rdsapi["AWS RDS API"]
        s3api["AWS S3 API"]
        sesapi["AWS SES API"]:::new
        snsapi["AWS SNS API"]:::new
        route53api["AWS Route 53 API"]
    end

    letsencrypt["Let's Encrypt API"]

    u -->|OSBAPI requests| capi

    capi --> awsbroker
    capi --> s3broker
    capi --> csb
    capi --> extbroker

    awsbroker --> rdsapi
    s3broker --> s3api
    csb --> sesapi
    csb --> snsapi
    csb --> route53api
    extbroker --> route53api
    extbroker --> letsencrypt
```

## New HTTP Services

New HTTP services introduced by the Cloud Service Broker SCR are in green. (For brevity, not all existing Cloud.gov web services are depicted.)

- The **CSB** fulfills provisioning and binding requests for certain service offerings.
- The **Documentation Proxy** is a server that displays documentation for service offerings maintained by the CSB. The CSB exposes a documentation endpoint, `docs/`. When a user makes a request to this service, the service GETs the `docs/` page and returns it to the user with some visual changes.
- The **Service Updater** regularly updates customer service instances so the instances stay up to date with the latest plans offered by the CSB. It may accept administrative HTTPS requests, but only on an internal domain.

```mermaid
---
title: "Figure 3: New HTTP Services"
---

flowchart LR
    classDef new fill:#ecffec,stroke:#73d893
    u["Cloud.gov Customer"]

    subgraph "AWS"

        subgraph "Cloud.gov"
            direction LR
            logs["logs.fr.cloud.gov - Cloud.gov Logs"]
            etc["(...other services...)"]
            capi["api.fr.cloud.gov - Cloud Foundry API"]
            csb-helper["services.cloud.gov - CSB Helper"]:::new

            subgraph "Service Brokers"
                csb["csb.app.cloud.gov - Cloud Service Broker"]:::new
            end
        end
    end


    u -->|Logs Dashboard| logs
    u -->|Other requests| etc
    u -->|OSBAPI requests| capi
    u -->|Documentation page| csb-helper
    capi --> csb
    csb-helper --> csb
```
