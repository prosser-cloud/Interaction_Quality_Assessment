public with sharing class QAFormResponseParser {
    
    @InvocableMethod(label='Process QA Assessment Response' description='Parses LLM response and updates Quality Assessment records')
    public static List<ProcessResult> processAssessmentResponse(List<ProcessRequest> requests) {
        ProcessRequest input = requests[0];
        List<ProcessResult> results = new List<ProcessResult>();
        ProcessResult result = new ProcessResult();
        results.add(result);
        
        try {
            Map<String, Object> responseData = (Map<String, Object>) JSON.deserializeUntyped(input.llmResponse);
            
            if (responseData.containsKey('assessmentResults')) {
                Object assessmentResults = responseData.get('assessmentResults');
                
                // Check if it's the error format: {"assessmentResults":{"Assessment Created":false,"Reason": "<reason>"}}
                if (assessmentResults instanceof Map<String, Object>) {
                    Map<String, Object> errorResult = (Map<String, Object>) assessmentResults;
                    if (errorResult.containsKey('Assessment Created') && !(Boolean) errorResult.get('Assessment Created')) {
                        result.success = false;
                        result.message = 'Assessment could not be created: ' + (String) errorResult.get('Reason');
                        return results;
                    }
                }
                
                // Process successful assessment format: {"assessmentResults":[{"questionId":"...","score":8,"additionalComments":"..."}],"overallComments":"..."}
                if (assessmentResults instanceof List<Object>) {
                    List<Object> questionResults = (List<Object>) assessmentResults;
                    String overallComments = (String) responseData.get('overallComments');
                    
                    ProcessAssessmentResult processResult = processQuestionResults(questionResults, input.qaFormId, overallComments);
                    result.success = processResult.success;
                    result.message = processResult.message;
                    result.overallScore = processResult.overallScore;
                    result.overallPassed = processResult.overallPassed;
                } else {
                    result.success = false;
                    result.message = 'Invalid response format: assessmentResults is not a list or error object';
                }
            } else {
                result.success = false;
                result.message = 'Invalid response format: missing assessmentResults';
            }
            
        } catch (Exception e) {
            result.success = false;
            result.message = 'Error processing response: ' + e.getMessage();
        }
        
        return results;
    }
    
    private static ProcessAssessmentResult processQuestionResults(List<Object> questionResults, String qaFormId, String overallComments) {
        ProcessAssessmentResult result = new ProcessAssessmentResult();
        
        try {
            // Get existing Quality Assessment Questions to update
            Map<String, Quality_Assessment_Question__c> questionsToUpdate = new Map<String, Quality_Assessment_Question__c>();
            
            List<Quality_Assessment_Question__c> existingQuestions = [
                SELECT Id, Question__c, Question__r.Pass_Fail__c, Question__r.Question_Weight__c 
                FROM Quality_Assessment_Question__c 
                WHERE Quality_Assessment__c = :qaFormId
            ];
            
            System.debug('Found ' + existingQuestions.size() + ' existing questions for QA Form: ' + qaFormId);
            
            // If no existing questions found, this might be a new assessment
            if (existingQuestions.isEmpty()) {
                result.success = false;
                result.message = 'No Quality Assessment Question records found for QA Form ID: ' + qaFormId + '. Please ensure the Quality Assessment Questions are created first.';
                return result;
            }
            
            for (Quality_Assessment_Question__c qa : existingQuestions) {
                questionsToUpdate.put(qa.Id, qa);
                System.debug('Available Question ID: ' + qa.Id);
            }
            
            List<Quality_Assessment_Question__c> questionsToUpdateList = new List<Quality_Assessment_Question__c>();
            Decimal totalWeightedScore = 0;
            Decimal totalWeight = 0;
            Boolean overallPassed = true;
            
            // Process each question result
            for (Object questionObj : questionResults) {
                Map<String, Object> questionData = (Map<String, Object>) questionObj;
                String questionId = (String) questionData.get('questionId');
                Integer score = (Integer) questionData.get('score');
                String additionalComments = (String) questionData.get('additionalComments');
                
                System.debug('Processing Question ID from LLM: ' + questionId + ' with score: ' + score);
                
                if (questionsToUpdate.containsKey(questionId)) {
                    System.debug('Found matching question for ID: ' + questionId);
                    Quality_Assessment_Question__c qaQuestion = questionsToUpdate.get(questionId);
                    
                    // Update question with score and comments
                    qaQuestion.Score__c = score;
                    qaQuestion.Additional_Comments__c = additionalComments;
                    questionsToUpdateList.add(qaQuestion);
                    
                    // Calculate weighted score
                    Decimal weight = qaQuestion.Question__r.Question_Weight__c != null ? qaQuestion.Question__r.Question_Weight__c : 1;
                    totalWeightedScore += score * weight;
                    totalWeight += weight;
                    
                    // Check pass/fail questions
                    if (qaQuestion.Question__r.Pass_Fail__c == true) {
                        if (score < 5) { // Consider scores below 5 as fail for pass/fail questions
                            overallPassed = false;
                        }
                    }
                } else {
                    System.debug('No matching question found for ID: ' + questionId);
                }
            }
            
            // Update Quality Assessment Questions
            if (!questionsToUpdateList.isEmpty()) {
                update questionsToUpdateList;
            }
            
            // Calculate overall score as weighted average
            Decimal overallScore = totalWeight > 0 ? (totalWeightedScore / totalWeight) : 0;
            
            // Update main Quality Assessment record
            Quality_Assessment__c qaRecord = new Quality_Assessment__c(
                Id = qaFormId,
                Overall_Score__c = overallScore
            );
            
            // Add overall comments field if it exists (assuming there might be one)
            // Note: This field doesn't exist in the metadata we saw, but including for completeness
            // qaRecord.Overall_Comments__c = overallComments;
            
            update qaRecord;
            
            result.success = true;
            result.message = 'Successfully updated ' + questionsToUpdateList.size() + ' questions and overall assessment';
            result.overallScore = overallScore;
            result.overallPassed = overallPassed;
            
        } catch (Exception e) {
            result.success = false;
            result.message = 'Error updating records: ' + e.getMessage();
        }
        
        return result;
    }
    
    public class ProcessRequest {
        @InvocableVariable(label='LLM Response' description='JSON response from the LLM' required=true)
        public String llmResponse;
        
        @InvocableVariable(label='QA Form ID' description='Quality Assessment record ID' required=true)
        public String qaFormId;
    }
    
    public class ProcessResult {
        @InvocableVariable(label='Success' description='Whether the processing was successful')
        public Boolean success;
        
        @InvocableVariable(label='Message' description='Result message')
        public String message;
        
        @InvocableVariable(label='Overall Score' description='Calculated overall score')
        public Decimal overallScore;
        
        @InvocableVariable(label='Overall Passed' description='Whether all pass/fail questions passed')
        public Boolean overallPassed;
    }
    
    private class ProcessAssessmentResult {
        public Boolean success;
        public String message;
        public Decimal overallScore;
        public Boolean overallPassed;
    }
}