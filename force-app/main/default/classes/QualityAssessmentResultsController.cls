public with sharing class QualityAssessmentResultsController {
    
    @AuraEnabled(cacheable=true)
    public static QualityAssessmentResults getQualityAssessmentResults(String recordId) {
        try {
            // Query the Quality Assessment record with all questions and template details
            Quality_Assessment__c qaRecord = [
                SELECT Id, Name, Overall_Score__c, Scored_Case__c, Scored_Voice_Call__c, Scored_Messaging_Session__c,
                       (SELECT Id, Score__c, Additional_Comments__c,
                               Question__r.Question__c, Question__r.Question_Details__c, Question__r.Question_Type__c,
                               Question__r.Question_Weight__c, Question__r.Question_Order__c, Question__r.Section__c,
                               Question__r.Pass_Fail__c, Question__r.Multi_Choice_Option_List__c
                        FROM Quality_Assessment_Questions__r
                        ORDER BY Question__r.Section__c, Question__r.Question_Order__c)
                FROM Quality_Assessment__c 
                WHERE Id = :recordId 
                LIMIT 1
            ];
            
            QualityAssessmentResults results = new QualityAssessmentResults();
            results.assessmentId = qaRecord.Id;
            results.assessmentName = qaRecord.Name;
            results.overallScore = qaRecord.Overall_Score__c;
            
            // Group questions by section
            Map<String, List<QuestionResult>> questionsBySection = new Map<String, List<QuestionResult>>();
            
            for (Quality_Assessment_Question__c question : qaRecord.Quality_Assessment_Questions__r) {
                String section = question.Question__r.Section__c != null ? question.Question__r.Section__c : 'General';
                
                if (!questionsBySection.containsKey(section)) {
                    questionsBySection.put(section, new List<QuestionResult>());
                }
                
                QuestionResult questionResult = new QuestionResult();
                questionResult.id = question.Id;
                questionResult.questionText = question.Question__r.Question__c;
                questionResult.questionDetails = question.Question__r.Question_Details__c;
                questionResult.questionType = question.Question__r.Question_Type__c;
                questionResult.weight = question.Question__r.Question_Weight__c;
                questionResult.score = question.Score__c;
                questionResult.additionalComments = question.Additional_Comments__c;
                questionResult.passFailQuestion = question.Question__r.Pass_Fail__c;
                questionResult.multiChoiceOptions = question.Question__r.Multi_Choice_Option_List__c;
                
                questionsBySection.get(section).add(questionResult);
            }
            
            // Convert to section results
            List<SectionResult> sectionResults = new List<SectionResult>();
            for (String sectionName : questionsBySection.keySet()) {
                SectionResult sectionResult = new SectionResult();
                sectionResult.sectionName = sectionName;
                sectionResult.questions = questionsBySection.get(sectionName);
                
                // Calculate section score
                Decimal totalScore = 0;
                Decimal totalWeight = 0;
                for (QuestionResult question : sectionResult.questions) {
                    if (question.score != null) {
                        Decimal weight = question.weight != null ? question.weight : 1;
                        totalScore += question.score * weight;
                        totalWeight += weight;
                    }
                }
                sectionResult.sectionScore = totalWeight > 0 ? totalScore / totalWeight : 0;
                
                sectionResults.add(sectionResult);
            }
            
            results.sections = sectionResults;
            return results;
            
        } catch (Exception e) {
            throw new AuraHandledException('Error fetching Quality Assessment results: ' + e.getMessage());
        }
    }
    
    public class QualityAssessmentResults {
        @AuraEnabled public String assessmentId;
        @AuraEnabled public String assessmentName;
        @AuraEnabled public Decimal overallScore;
        @AuraEnabled public List<SectionResult> sections;
    }
    
    public class SectionResult {
        @AuraEnabled public String sectionName;
        @AuraEnabled public Decimal sectionScore;
        @AuraEnabled public List<QuestionResult> questions;
    }
    
    public class QuestionResult {
        @AuraEnabled public String id;
        @AuraEnabled public String questionText;
        @AuraEnabled public String questionDetails;
        @AuraEnabled public String questionType;
        @AuraEnabled public Decimal weight;
        @AuraEnabled public Decimal score;
        @AuraEnabled public String additionalComments;
        @AuraEnabled public Boolean passFailQuestion;
        @AuraEnabled public String multiChoiceOptions;
    }
}