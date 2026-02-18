global class CaseInteractionRetriever {
    @InvocableMethod(label='Retrieve Case Interactions' 
                     description='Retrieves CaseFeed, VoiceCalls, MessagingSessions, and EmailMessages related to a case' 
                     category='Case Management')
    global static List<Result> retrieveInteractions(List<Request> requests) {
        List<Result> results = new List<Result>();
        
        for (Request req : requests) {
            Result res = new Result();
            String caseId = req.caseId;
            String transcriptFlowName = req.transcriptFlowName;
            
            // Create JSON structure
            JSONGenerator gen = JSON.createGenerator(true);
            gen.writeStartObject();
            
            // Query CaseFeed items (TextPost only)
            gen.writeFieldName('CaseFeed');
            gen.writeStartArray();
            
            List<CaseFeed> caseFeeds = [
                SELECT Id, Body, CreatedById, CreatedDate, ParentId, Visibility
                FROM CaseFeed
                WHERE ParentId = :caseId AND Type = 'TextPost'
                ORDER BY CreatedDate ASC
            ];
            
            Map<Id, User> userMap = new Map<Id, User>();
            Map<Id, Contact> contactMap = new Map<Id, Contact>();
            
            Set<Id> createdByIds = new Set<Id>();
            for (CaseFeed feed : caseFeeds) {
                createdByIds.add(feed.CreatedById);
            }
            
            // Query User names
            for (User u : [SELECT Id, FirstName, LastName FROM User WHERE Id IN :createdByIds]) {
                userMap.put(u.Id, u);
            }
            
            // Query Contact names (in case CreatedById refers to a contact)
            for (Contact c : [SELECT Id, FirstName, LastName FROM Contact WHERE Id IN :createdByIds]) {
                contactMap.put(c.Id, c);
            }
            
            for (CaseFeed feed : caseFeeds) {
                gen.writeStartObject();
                gen.writeStringField('Id', feed.Id != null ? feed.Id : '');
                // Handle null Body field
                gen.writeStringField('Body', feed.Body != null ? feed.Body : '');
                gen.writeStringField('CreatedById', feed.CreatedById != null ? feed.CreatedById : '');
                
                // Include creator name
                String creatorName = 'Unknown';
                if (userMap.containsKey(feed.CreatedById)) {
                    User u = userMap.get(feed.CreatedById);
                    creatorName = u.FirstName + ' ' + u.LastName;
                } else if (contactMap.containsKey(feed.CreatedById)) {
                    Contact c = contactMap.get(feed.CreatedById);
                    creatorName = c.FirstName + ' ' + c.LastName;
                }
                
                gen.writeStringField('CreatedByName', creatorName);
                if (feed.CreatedDate != null) {
                    gen.writeDateTimeField('CreatedDate', feed.CreatedDate);
                } else {
                    gen.writeNullField('CreatedDate');
                }
                // Handle null Visibility field
                gen.writeStringField('Visibility', feed.Visibility != null ? feed.Visibility : '');
                gen.writeEndObject();
            }
            
            gen.writeEndArray();
            
            // Query VoiceCalls
            gen.writeFieldName('VoiceCalls');
            gen.writeStartArray();
            
            List<VoiceCall> voiceCalls = [
                SELECT Id, Name, CreatedDate
                FROM VoiceCall
                WHERE RelatedRecordId = :caseId
                ORDER BY CreatedDate ASC
            ];
            
            for (VoiceCall call : voiceCalls) {
                gen.writeStartObject();
                gen.writeStringField('Id', call.Id != null ? call.Id : '');
                gen.writeStringField('Name', call.Name != null ? call.Name : '');
                if (call.CreatedDate != null) {
                    gen.writeDateTimeField('CreatedDate', call.CreatedDate);
                } else {
                    gen.writeNullField('CreatedDate');
                }
                
                // Only get transcript if a flow name is provided
                if (String.isNotBlank(transcriptFlowName)) {
                    // Call the flow to get the transcript
                    String transcript = getTranscriptFromFlow(call.Id, transcriptFlowName);
                    gen.writeStringField('Transcript', transcript != null ? transcript : '');
                }
                
                gen.writeEndObject();
            }
            
            gen.writeEndArray();
            
            // Query MessagingSessions
            gen.writeFieldName('MessagingSessions');
            gen.writeStartArray();
            
            List<MessagingSession> messagingSessions = [
                SELECT Id, Name, CreatedDate
                FROM MessagingSession
                WHERE CaseId = :caseId
                ORDER BY CreatedDate ASC
            ];
            
            for (MessagingSession session : messagingSessions) {
                gen.writeStartObject();
                gen.writeStringField('Id', session.Id != null ? session.Id : '');
                gen.writeStringField('Name', session.Name != null ? session.Name : '');
                if (session.CreatedDate != null) {
                    gen.writeDateTimeField('CreatedDate', session.CreatedDate);
                } else {
                    gen.writeNullField('CreatedDate');
                }
                
                // Only get transcript if a flow name is provided
                if (String.isNotBlank(transcriptFlowName)) {
                    // Call the flow to get the transcript
                    String transcript = getTranscriptFromFlow(session.Id, transcriptFlowName);
                    gen.writeStringField('Transcript', transcript != null ? transcript : '');
                }
                
                gen.writeEndObject();
            }
            
            gen.writeEndArray();
            
            // Query EmailMessages - Include Email bodies directly
            gen.writeFieldName('EmailMessages');
            gen.writeStartArray();
            
            List<EmailMessage> emailMessages = [
                SELECT Id, Subject, FromName, FromAddress, ToAddress, CcAddress, 
                       SDO_Service_Email_Summary__c, TextBody, HtmlBody, CreatedDate
                FROM EmailMessage
                WHERE ParentId = :caseId
                ORDER BY CreatedDate ASC
            ];
            
            for (EmailMessage email : emailMessages) {
                gen.writeStartObject();
                gen.writeStringField('Id', email.Id != null ? email.Id : '');
                gen.writeStringField('Subject', email.Subject != null ? email.Subject : '');
                gen.writeStringField('FromName', email.FromName != null ? email.FromName : '');
                gen.writeStringField('FromAddress', email.FromAddress != null ? email.FromAddress : '');
                gen.writeStringField('ToAddress', email.ToAddress != null ? email.ToAddress : '');
                gen.writeStringField('CcAddress', email.CcAddress != null ? email.CcAddress : '');
                if (email.CreatedDate != null) {
                    gen.writeDateTimeField('CreatedDate', email.CreatedDate);
                } else {
                    gen.writeNullField('CreatedDate');
                }
                
                // Use SDO_Service_Email_Summary__c if not empty, otherwise use TextBody, if TextBody is empty use HtmlBody
                String messageContent = '';
                if (email.SDO_Service_Email_Summary__c != null && email.SDO_Service_Email_Summary__c.trim() != '') {
                    messageContent = email.SDO_Service_Email_Summary__c;
                } else if (email.TextBody != null && email.TextBody.trim() != '') {
                    messageContent = email.TextBody;
                } else if (email.HtmlBody != null) {
                    messageContent = email.HtmlBody;
                }
                
                // Ensure we're including the email body content in the JSON
                gen.writeStringField('Content', messageContent);
                gen.writeEndObject();
            }
            
            gen.writeEndArray();
            gen.writeEndObject();
            
            res.jsonOutput = gen.getAsString();
            results.add(res);
        }
        
        return results;
    }
    
    // Helper method to dynamically call a flow based on its name
    private static String getTranscriptFromFlow(String recordId, String flowName) {
        try {
            // First, ensure the flow exists and is active by querying it
            // This helps avoid using inactive versions
            List<FlowDefinitionView> flowDefinitions = [
                SELECT Id, ApiName, Label, IsActive, LatestVersionId
                FROM FlowDefinitionView 
                WHERE ApiName = :flowName AND IsActive = true
                LIMIT 1
            ];
            
            if (flowDefinitions.isEmpty()) {
                return 'Flow "' + flowName + '" not found or not active';
            }
            
            // Handle null recordId
            if (recordId == null) {
                return 'Record ID is null';
            }
            
            // Prepare the input parameters for the Flow
            Map<String, Object> flowInputs = new Map<String, Object>();
            flowInputs.put('recordId', recordId);
            
            // Call the Flow
            Flow.Interview flow = Flow.Interview.createInterview(flowName, flowInputs);
            flow.start();
            
            // Get the output from the Flow
            String transcript = (String) flow.getVariableValue('transcript');
            
            // Return the transcript if not null
            if (transcript != null) {
                return transcript;
            }
            return 'No transcript available';
        } catch (Exception e) {
            return 'Error retrieving transcript: ' + e.getMessage();
        }
    }
    
    // Input class for the invocable method
    global class Request {
        @InvocableVariable(label='Case ID' required=true)
        global String caseId;
        
        @InvocableVariable(label='Transcript Flow API Name' required=false description='API name of the flow to retrieve transcripts. Leave blank to skip transcript retrieval.')
        global String transcriptFlowName = 'Get_Transcript';
    }
    
    // Output class for the invocable method
    global class Result {
        @InvocableVariable(label='JSON Output')
        global String jsonOutput;
    }
}