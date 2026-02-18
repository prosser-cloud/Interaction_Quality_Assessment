# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Salesforce DX project for an Interaction Quality Assessment application. The project focuses on quality assurance functionality for evaluating customer interactions across different channels (cases, messaging sessions, and voice calls).

## Core Architecture

### Custom Objects Structure
The application is built around several interconnected custom objects:

- **Quality_Assessment__c**: Main assessment record linked to Case, MessagingSession, or VoiceCall
- **Quality_Assessment_Question__c**: Individual assessment question responses with scores and comments
- **Quality_Assurance_Question__c**: Question templates defining the assessment criteria
- **ai_QualityAssuranceQuestionnaire__c**: Questionnaire templates containing multiple questions

### Key Relationships
- Quality assessments can be associated with Cases, MessagingSession, or VoiceCall records
- VoiceCall objects have a lookup to Quality Assurance Questionnaires
- Questions are organized with sections, weights, and ordering for structured assessments

## Development Commands

### Testing
```bash
npm run test              # Run all unit tests
npm run test:unit:watch   # Run tests in watch mode
npm run test:unit:debug   # Run tests in debug mode
npm run test:unit:coverage # Run tests with coverage report
```

### Code Quality
```bash
npm run lint              # Lint Aura and LWC JavaScript files
npm run prettier          # Format all supported file types
npm run prettier:verify   # Check formatting without making changes
```

### Salesforce Development
This project uses standard Salesforce DX commands. The main source is in `force-app/main/default/`.

## Project Configuration

- **Source API Version**: 64.0
- **Package Directory**: `force-app` (default)
- **Project Name**: Interaction_Quality_Assessment
- **No namespace** defined

## Code Standards

- ESLint configured for both Aura and LWC components with Salesforce recommended configs
- Prettier formatting enforced for all file types including Apex (.cls), components, and metadata
- Jest testing framework configured specifically for LWC with sfdx-lwc-jest
- Husky pre-commit hooks run formatting and linting automatically

## File Structure

The project follows standard Salesforce DX structure:
- Custom objects and fields in `objects/`
- Lightning Web Components in `lwc/` (when created)
- Aura components in `aura/` (when created)  
- Apex classes in `classes/` (when created)
- Other metadata in respective folders under `force-app/main/default/`


Add Apex Merge Fields to a Flex Prompt Template
Create an example Flex prompt template that uses Apex.

Required Editions
Available in: Lightning Experience
Available in: Enterprise, Performance, and Unlimited Editions with the Einstein for Platform, or Einstein or Agentforce for Sales or Service add-on, or Agentforce Foundations
User Permissions Needed
To create and manage prompt templates in Prompt Builder:	Prompt Template Manager permission set
Before adding the Apex fields, create an Apex class to use as a resource in the template. The class’s input variables must be a subset of the inputs to the template. The API name in the Apex class must match the API name in the template for each String input type and for any sobject input type used for more than one input in the template.

For instance, this example has two Account inputs in the prompt. To distinguish them, the object API names must match the corresponding template inputs. The single Case input does not need to match because there’s only one input of the Case type. You create the template API Name fields and their input when you create the prompt template in the UI.

public class ApexFlexTemplateExample1 {
 
    @InvocableMethod
    public static List<Response> getPrompt(List<Request> requests) {
        Request input = requests[0];
        List<Response> responses = new List<Response>();
        Response output = new Response();
        responses.add(output);
   
        output.Prompt = 'generate a summary using the following info:';
        // account_1 matches the API Name for the input
        output.Prompt += '\nAccount 1: ' + input.account_1.Name;
        output.Prompt += '\nAccount 2: ' + input.account_2.Name;
        output.Prompt += '\nCase Number: ' + input.case_1.CaseNumber;

        return responses;
    }
 
    // Type and API Name of all variables must match the template
    public class Request {
        @InvocableVariable(required=true)
        public Account account_1;
        @InvocableVariable(required=true)
        public Account account_2;
        @InvocableVariable(required=true)
        public Case case_1;
    }

    public class Response {
        @InvocableVariable
        public String Prompt;
    }
}   
Note
Note The output variable in the Response class should always be named "Prompt" in order for it to be discovered by the Resource Picker in the Prompt Builder UI.
In this example, we create a flex template that takes two accounts and one case.

In Prompt Builder, click New Prompt Template.
In the Prompt Template Type field, select Flex.
In the Prompt Template Name field, enter Flex - Apex Example1.
In the Define Resources section, enter the objects that the template uses.
For the first row, enter account 1 in the Name field. In the Object field, select Account. Click Add Resources.
For the second row, enter account 2 in the Name field. In the Object field, select Account. Click Add Resources.
For the third row, enter case 1 in the Name field. In the Object field, select Case.
Click Next.
Click Save.
Reload the template.
In Prompt Builder, add the ApexFlexTemplateExample1 class as a resource in the Flex template.

This example shows you how to send inputs for a Flex prompt template to an Apex class. The use case is simple but the concept is powerful. You can use Apex to process the records for your real-world use case.