#Title: Dependency Tracker: SQL Component Dependency and Hierarchy Analysis

Project Overview

The Dependency Tracker is a tool designed to optimize a large SQL database by identifying and removing obsolete or unused components, such as tables, views, and stored procedures. In addition to database optimization, the tool analyzes the dependencies between various components to provide a clear hierarchy of direct and indirect interactions. This improves the maintainability and performance of the database, streamlining future development efforts.

Objective

The main objectives of the Dependency Tracker are:

1. Identify and assess unused or obsolete database components.
2. Optimize database performance by removing unnecessary components.
3. Build a hierarchy tree that highlights direct and indirect dependencies between SQL components, such as stored procedures, tables, and views.

Features

1. Dependency Hierarchy Mapping: Recursive analysis of SQL components to map out direct and indirect dependencies.
2. Obsolete Component Identification: Detection of unused or outdated components that are candidates for removal.
3. Comprehensive Reporting: Generate visual reports of component hierarchies using SQL Server Reporting Services (SSRS).
4. Regular Audits: Recommendations for ongoing maintenance and auditing of database components to keep the dependency tracker accurate.

Technology Stack

1. Python: For data extraction, cleaning, and analysis. Python scripts are used to process SQL queries and identify dependencies.
2. SQL Server: The core platform for database management and running the dependency analysis.
3. SQL Server Reporting Services (SSRS): For generating visual reports of the dependency hierarchy tree, making the analysis results easier to interpret.

Installation Prerequisites
1. Python: Install Python 3.6 or later.
2. SQL Server: A running instance of SQL Server to analyze the database.
3. SSRS: Install SQL Server Reporting Services for generating reports
