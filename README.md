# Interaction Quality Assessment

A sample Salesforce package for evaluating customer interaction quality across multiple channels including Cases, Messaging Sessions, and Voice Calls.

## Overview

This package provides a sample configuration for a structured framework for quality assurance teams to assess and score customer interactions using configurable questionnaires. It leverages AI-powered scoring capabilities to ensure consistent quality evaluation across all customer touchpoints. This package should _not_ be deployed as is, it should be used as an example. This project was developed using, in part, AI. 

## Key Features

- **Multi-Channel Assessment**: Evaluate quality across Cases, Messaging Sessions, and Voice Calls
- **AI-Powered Scoring**: Automated quality assessment using GenAI prompt templates
- **Configurable Questionnaires**: Flexible question templates with sections, weights, and ordering
- **Comprehensive Reporting**: Detailed results with section-based scoring and comments
- **Multiple Questionnaires**: Direct association of questionnaires with interaction records to tailer assessments for the type of interaction
## Architecture

### Core Custom Objects

- **Quality_Assessment__c**: Individual assessment record linked to interaction records (Such as case or voice call)
- **Quality_Assessment_Question__c**: Individual assessment question with responses, scores and comments
- **Quality_Assurance_Question__c**: Template questions defining assessment criteria
- **ai_QualityAssuranceQuestionnaire__c**: Template questionnaire containers organizing multiple questions
- **Case** (Extended): Adds quality assurance questionnaire lookup
- **MessagingSession** (Extended): Adds quality assurance questionnaire lookup
- **VoiceCall** (Extended): Adds quality assurance questionnaire lookup

### Key Relationships

```
Quality_Assessment__c
├── Lookup to Case
├── Lookup to MessagingSession
├── Lookup to VoiceCall
└── Child: Quality_Assessment_Question__c
    └── Lookup to Quality_Assurance_Question__c
        └── Master-Detail to ai_QualityAssuranceQuestionnaire__c
```

## Components

### Lightning Web Components

- **qualityAssessmentResults**: Displays comprehensive assessment results with section-based scoring

### Apex Classes

- **QualityAssessmentResultsController**: Server-side controller for LWC results data retrieval
- **QAFormResponseParser**: Parses and processes quality assessment form prompt responses
- **ground_qa_form**: Generates qa form structure in JSON for ai prompt consumption

### AI Integration

- **Score_QA_Form**: GenAI prompt template for automated quality scoring
- **Ground_with_Record_Data**: Flow for adding record context to AI Prompt
- **Process_QA_Forms**: Flow for automatically creating assessement from questionairre 

### User Interface

- **Quality_Assurance_Questionnaire_Record_Page**: Lightning record page for questionnaire management
