
public with sharing class ground_qa_form {
    
    @InvocableMethod(label='Get QA Form Data' description='Retrieves Quality Assessment and related data for prompt templates')
    public static List<Response> getQAFormData(List<Request> requests) {
        Request input = requests[0];
        List<Response> responses = new List<Response>();
        Response output = new Response();
        responses.add(output);
        
        try {
            // Query the Quality Assessment record with all related data
            Quality_Assessment__c qaRecord = [
                SELECT Id, Name, Overall_Score__c, Scored_Case__c, Scored_Voice_Call__c, Scored_Messaging_Session__c,
                       (SELECT Id, Question__c, Score__c, Additional_Comments__c,
                               Question__r.Question__c, Question__r.Question_Details__c, Question__r.Question_Type__c,
                               Question__r.Question_Weight__c, Question__r.Question_Order__c, Question__r.Section__c,
                               Question__r.Pass_Fail__c, Question__r.Multi_Choice_Option_List__c
                        FROM Quality_Assessment_Questions__r)
                FROM Quality_Assessment__c 
                WHERE Id = :input.qaForm 
                LIMIT 1
            ];
            
            // Query the related record (Case, VoiceCall, or MessagingSession)
            SObject relatedRecord = null;
            if (qaRecord.Scored_Case__c != null) {
                relatedRecord = [SELECT Id, CaseNumber, Subject, Status, Priority, Description FROM Case WHERE Id = :qaRecord.Scored_Case__c LIMIT 1];
            } else if (qaRecord.Scored_Voice_Call__c != null) {
                relatedRecord = [SELECT Id, Name FROM VoiceCall WHERE Id = :qaRecord.Scored_Voice_Call__c LIMIT 1];
            } else if (qaRecord.Scored_Messaging_Session__c != null) {
                relatedRecord = [SELECT Id, Name FROM MessagingSession WHERE Id = :qaRecord.Scored_Messaging_Session__c LIMIT 1];
            }
            
            // Build JSON response
            Map<String, Object> qaData = new Map<String, Object>();
            qaData.put('qualityAssessment', buildQAData(qaRecord));
            qaData.put('relatedRecord', buildRelatedRecordData(relatedRecord));
            qaData.put('questions', buildQuestionsData(qaRecord.Quality_Assessment_Questions__r));
            
            output.Prompt = JSON.serialize(qaData);
            
        } catch (Exception e) {
            output.Prompt = JSON.serialize(new Map<String, String>{'error' => e.getMessage()});
        }
        
        return responses;
    }
    
    private static Map<String, Object> buildQAData(Quality_Assessment__c qa) {
        Map<String, Object> qaMap = new Map<String, Object>();
        qaMap.put('Id', qa.Id);
        qaMap.put('Name', qa.Name);
        qaMap.put('OverallScore', qa.Overall_Score__c);
        qaMap.put('ScoredCase', qa.Scored_Case__c);
        qaMap.put('ScoredVoiceCall', qa.Scored_Voice_Call__c);
        qaMap.put('ScoredMessagingSession', qa.Scored_Messaging_Session__c);
        return qaMap;
    }
    
    private static Map<String, Object> buildRelatedRecordData(SObject record) {
        Map<String, Object> recordMap = new Map<String, Object>();
        if (record != null) {
            recordMap.put('Id', record.Id);
            recordMap.put('ObjectType', record.getSObjectType().getDescribe().getName());
            
            // Add specific fields based on object type
            if (record instanceof Case) {
                Case caseRecord = (Case) record;
                recordMap.put('CaseNumber', caseRecord.CaseNumber);
                recordMap.put('Subject', caseRecord.Subject);
                recordMap.put('Status', caseRecord.Status);
                recordMap.put('Priority', caseRecord.Priority);
                recordMap.put('Description', caseRecord.Description);
            } else {
                recordMap.put('Name', record.get('Name'));
            }
        }
        return recordMap;
    }
    
    private static List<Map<String, Object>> buildQuestionsData(List<Quality_Assessment_Question__c> questions) {
        List<Map<String, Object>> questionsList = new List<Map<String, Object>>();
        for (Quality_Assessment_Question__c question : questions) {
            Map<String, Object> questionMap = new Map<String, Object>();
            questionMap.put('Id', question.Id);
            questionMap.put('Score', question.Score__c);
            questionMap.put('AdditionalComments', question.Additional_Comments__c);
            
            // Add Quality Assurance Question details
            if (question.Question__r != null) {
                Map<String, Object> qaQuestionDetails = new Map<String, Object>();
                qaQuestionDetails.put('Question', question.Question__r.Question__c);
                qaQuestionDetails.put('QuestionDetails', question.Question__r.Question_Details__c);
                qaQuestionDetails.put('QuestionType', question.Question__r.Question_Type__c);
                qaQuestionDetails.put('QuestionWeight', question.Question__r.Question_Weight__c);
                qaQuestionDetails.put('QuestionOrder', question.Question__r.Question_Order__c);
                qaQuestionDetails.put('Section', question.Question__r.Section__c);
                qaQuestionDetails.put('PassFail', question.Question__r.Pass_Fail__c);
                qaQuestionDetails.put('MultiChoiceOptionList', question.Question__r.Multi_Choice_Option_List__c);
                questionMap.put('QuestionTemplate', qaQuestionDetails);
            }
            
            questionsList.add(questionMap);
        }
        return questionsList;
    }
    
    public class Request {
        @InvocableVariable(required=true)
        public String recordId;
        
        @InvocableVariable(required=true)
        public String qaForm;
    }
    
    public class Response {
        @InvocableVariable
        public String Prompt;
    }
}