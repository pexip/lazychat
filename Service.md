# LazyChat Service

## Introduction

This document describes the LazyChat Service and the infrastructure running it.  Like all service documents, it is a living document and will likely benefit from your input.  Because this is a fake service used to test my abilities, there are extra sections(Time Tracking) which would not normally appear in a typical service document.  In addition, I use the first-person “I” instead of “we” to choose the lesser confusion.

## Service Description

The service "Laxy Chat" is a simple, anonymous-ish web-based chat app. 

### Infrastructure

The app is a standalone GoLang binary, and makes use of an internal channel to send and receive messages between users. 
The service is runs on kubernetes cluster in GCP in the europe-north1 region. No failover or multiregional setup is in place. 

### Security

The app appears to be extremely insecure, as it allows arbitrary, anonmymous user input.  If it is to be run, it should be accessible only by internal, trusted users.

### Documentation

No documentation is available aside from this document and the [README](readme.md)

## SLOs

Three SLOs are defined for the service, based on error rate, uptime, and throughput.

  * SLO 1: Error Rate: >95% of messages per day should be sent successfully.  This is an extremely low threshold, but even simple testing creates a lower success rate.
  * SLO 2: Uptime: The main page should respond correctly > 99.9% of the time per day.
  * SLO 3: Throughput: The service should handle up to 300 messages / s  UNIMPLEMENTED

# Judgement

The LazyChat app as presented is recommended for **Rejected - Needs Work**.  
  * The app frequently fails (see dash)
  * The app exhibits significant latency
  * The app fails with messages above 512 bytes
  * The app relies on javascript to set names
  * The app allows arbitrary input
  * The intended user base is not specified

## Design Choices

### OS

  * Scratch Image - the app runs as a standalone Golang binary. It does not require and would not benefit from a slim base image, which would add additional potential points of risk
  * User - I chose to use user 1000, which will limit privileges in the event the binary is hacked
  * Read-Only File System - I mount as much of the file system as possible as read-only, which will at the very least inconvenience a hacker

## Platform

### Infrastructure as Code

I use Terraform to deploy code to GCP.  Alternatives include Ansible, Deployment Manager, and other services.  I chose Terraform because it is at least somewhat cloud-agnostic and I wanted to try it out, but this is a personal choice.  Ansible or Deployment Manager would also be fine choices for this purpose.

#### Module

Being new to GCP, I choose to base my setup on the Simple Regional Cluster with Networking https://github.com/terraform-google-modules/terraform-google-kubernetes-engine/tree/master/examples/simple_regional_with_networking .  This required a small amount of editing to adapt to the current terraform version (0.15.0)

#### Ingress

I wasted a lot of time trying to set up networking.  The terraform provider I tried (https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/ingress) hung, and trying directly with kubectl (https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v0.45.0/deploy/static/provider/cloud/deploy.yaml) failed due to insufficient permissions (container.clusterRoles.create, container.clusterRoleBindings.create, container.roles.create, container.roleBindings.create, container.clusterRoles.create, container.clusterRoleBindings.create, container.roles.create, container.roleBindings.create).  In a real world setting I would have more time for debugging, or ideally I would talk to a colleague more familiar with GKE and Kubernetes. 

#### Monitoring

Basic monitoring has been added in the following ways:
  * App Instrumentation: the app has been instrumented to track its own failures, latency, and standard Golang stats including memory, objects, routines, and garbage collection
  * Uptime monitoring: the availability of the app is tracked through [blackbox](https://github.com/prometheus/blackbox_exporter) 
  * Metrics collection: the above metrics are collected in [prometheus](https://prometheus.io/) and visualized in [grafana](https://grafana.com/oss/grafana/) Configuration of prometheus is [here](metrics/prometheus.yml)
  * Dashboard & Alerts: the [dashboard](metrics/Lazy_Chat_App.json) is grafana-ready and contains graphs and alerts, although the alerts are not sent anywhere

## Planned Improvements

The service documented here is set in development at a rudimentary level.  Potential improvements include:

### Infrastructure

  * Redundant regions with failover
  * Replace the internal channel with a queueing service for messages, such as kafka
    * Improved scalabiilty
    * More seamless user experience as pods scale up & down
  * Access - I assume that the app’s endpoint should be limited to trusted, internal users
  * TLS - Without an explicit specification, network traffic should be encrypted by default

### Application

  * Add user authentication
  * Improve user name and message checks to defend from hacking, fraud, etc
  * Add selectable queues

### TODO

  * Fix Ingress
  * Better docker versioning
  * Instrument Hub
  * Cluster Dashboard (use existing GCP services?)
  * Logging (use existing GCP services?)
  * More alerting
  * Work with dev team to understand what they want from this - why not use one of many existing messaging services?

## Done

  * Update docker file
  * Deploy to cloud
  * Instrument Client
  * Basic App Dashboard
  * App alert
  * Basic App testing

# Time Tracking

2021/4/14: 3h - Get docker working, play with app
2021/4/18: 3h - Learn about GCP & Terraform, install terraform, start writing documentation, start playing with gcloud
2021/4/23: 5h - Deploy to gcloud using Terraform, 4h - Bang my head against ingress
2021/4/25: 6h - Bang head against ingress, instrument code, set up dashboards, document efforts

Total: 23h
