---
title: Home
layout: home
nav_order: 1
permalink: /
---
# Write code, not executable configuration files
{: .fs-9}

A good task runner should stay out of your way, not hamper your productivity. Your build process should be as testable and as maintainable as your application code-- not tied up in a proprietary configuration format.
{: .fs-6 .fw-300 }


## About

Tisktask was born out of a frustration from debugging existing task runners. Hours spent trying to re-run pipelines only to discover that:
- The config format for the shared action was slightly wrong
- The script embedded in the pipeline step had a misspelling
- The syntax for the embedded script was wrong, but was hidden by YAML highlighting

Many have attempted to redefine task runners, to build something better. However, all of them fall into the same trap: building walled gardens where simple scripts become complex "pipeline configurations", selling you compute time for tasks that could run on your laptop, and forcing you to learn their proprietary formats just to run basic commands.

This means that task runners need to control for a few fixed parameters:
- Running untrusted code on their VMs
- Running time-unbounded code on their VMs

Most task runners and CI/CD systems promise simplicity but lock you into their proprietary formats, environments, and workflows.

What if we embraced the idea that a pipeline is simply a set of interdependent processes meant to deliver software? What if we used conventions over configuration, encouraging libraries of task-related code instead of using YAML as a package manager?

Enter Tisktask. By placing executable files in conventional locations, the engine knows exactly what to run and when to run it. Use your favorite package manager to share code, write library folders, and structure tasks the way you would structure production-level software. No special syntax required.

Tisktask does not pretend like the complexity of your software system is reducible to a single line of pre-determined configuration. We let you write those abstractions.

Ready to break free of YAML? Check out our [Getting Started](/docs/getting-started.html) page to learn more.

