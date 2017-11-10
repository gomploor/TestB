public class ChatterIssues{
    
    public class ChatterPostInfo{
        public Id recordId {get;set;}
        public Id assignedToId {get; set;}
        public Id oldAssignedToId {get; set;}
        public String objectType {get;set;}
        public Id objectId {get;set;}
        public id stepId {get; set;}
        public Id cpId {get;set;}
        public String name {get; set;}
        public String type {get;set;}
        public String wrStatus {get;set;}
        public String oldWrStatus {get;set;}
        public String completedDate {get;set;}
        public Boolean newRecord {get;set;}
    }
    public List<ChatterPostInfo> chatterPostList {get;set;}
 
    public String baseUrl {get;set;}
    public Map<Id, Campaign_Profile__c> cpMap;
    public Map<Id, Id> amMap;
    public Map<Id, Id> emMap;
    public Map<Id, User> assignedMap;
    public static final String campaignProfileObjectType = 'campaign_profile__c';
    public static final String changeRequestObjectType = 'change_request__c';
    public static final String caseObjectType = 'case';
    public static final String amRole = 'AM';
    public static final String emRole = 'Email Coordinator';
    public Map<Id, WR_BPM__Flow_Instance_Issue__c> issueMap;
    public Map<Id, WR_BPM__Flow_Instance_Cursor__c> cursorMap;
    public Map<Id, WR_BPM__Flow_Instance_History__c> historyMap;
    
    public ChatterIssues(List<WR_BPM__Flow_Instance_Issue__c> issueList, List<WR_BPM__Flow_Instance_Issue__c> oldIssueList){
        
        baseUrl = URL.getSalesforceBaseUrl().toExternalForm(); 
        Map<Id, WR_BPM__Flow_Instance_Issue__c> issMap = new Map<Id, WR_BPM__Flow_Instance_Issue__c>(issueList); 
        Map<Id, WR_BPM__Flow_Instance_Issue__c> oldIssMap;
        
        if(oldIssueList != null)
            oldIssMap = new Map<Id, WR_BPM__Flow_Instance_Issue__c>(oldIssueList); 
        issueMap = new Map<Id, WR_BPM__Flow_Instance_Issue__c>
                ([Select Id, Name, WR_BPM__Flow_Instance__r.WR_BPM__Object_Id__c, WR_BPM__Flow_Instance__r.WR_BPM__Object_Type__c, CampaignProfile__c,
                 WR_BPM__Step__r.Name, WR_BPM__Assign_To__c, WR_BPM__Status__c
                 from WR_BPM__Flow_Instance_Issue__c
                 where Id IN :issMap.keySet()]);
        
        chatterPostList = new List<ChatterPostInfo>();
        for(WR_BPM__Flow_Instance_Issue__c issue :issueList)
            chatterPostList.add(getInfo(issueMap.get(issue.Id), (oldIssMap != null ? oldIssMap.get(issue.Id) : null)));
            
        getMaps();
        postChatter();
    }
    
    public ChatterIssues(List<WR_BPM__Flow_Instance_Cursor__c> cursorList, List<WR_BPM__Flow_Instance_Cursor__c> oldCursorList){
        baseUrl = URL.getSalesforceBaseUrl().toExternalForm(); 
        Map<Id, WR_BPM__Flow_Instance_Cursor__c> curMap = new Map<Id, WR_BPM__Flow_Instance_Cursor__c>(cursorList); 
        Map<Id, WR_BPM__Flow_Instance_Cursor__c> oldCurMap;
        
        if(oldCursorList != null)
            oldCurMap = new Map<Id, WR_BPM__Flow_Instance_Cursor__c>(oldCursorList); 
            
        cursorMap = new Map<Id, WR_BPM__Flow_Instance_Cursor__c>
                ([Select Id, Name, WR_BPM__Flow_Instance__r.WR_BPM__Object_Id__c, WR_BPM__Flow_Instance__r.WR_BPM__Object_Type__c, WR_BPM__Flow_Instance__r.Campaign_Profile__c,
                 WR_BPM__Step__r.Name, WR_BPM__Step__c, WR_BPM__Step_Assigned_To__c
                 from WR_BPM__Flow_Instance_Cursor__c
                 where Id IN :curMap.keySet()]);
        
        chatterPostList = new List<ChatterPostInfo>();
        for(WR_BPM__Flow_Instance_Cursor__c cur :cursorList)
            chatterPostList.add(getInfo(cursorMap.get(cur.Id), (oldCurMap != null ? oldCurMap.get(cur.Id) : null)));
            
        getMaps();
        postChatter();
    }
    
    public ChatterIssues(List<WR_BPM__Flow_Instance_History__c> histList, List<WR_BPM__Flow_Instance_History__c> oldHistList){
        baseUrl = URL.getSalesforceBaseUrl().toExternalForm(); 
        Map<Id, WR_BPM__Flow_Instance_History__c> histMap = new Map<Id, WR_BPM__Flow_Instance_History__c>(histList); 
        Map<Id, WR_BPM__Flow_Instance_History__c> oldHistMap;
        
        if(oldHistList != null)
            oldHistMap = new Map<Id, WR_BPM__Flow_Instance_History__c>(oldHistList); 
            
        historyMap = new Map<Id, WR_BPM__Flow_Instance_History__c>
                ([Select Id, Name, WR_BPM__Cursor__r.WR_BPM__Flow_Instance__r.WR_BPM__Object_Id__c, WR_BPM__Cursor__r.WR_BPM__Flow_Instance__r.WR_BPM__Object_Type__c, 
                    WR_BPM__Cursor__r.WR_BPM__Flow_Instance__r.Campaign_Profile__c, WR_BPM__Step__r.Name, WR_BPM__Step__c, WR_BPM__Assigned_To__c, WR_BPM__Completed_Date__c
                 from WR_BPM__Flow_Instance_History__c
                 where Id IN :histMap.keySet()]);
        
        chatterPostList = new List<ChatterPostInfo>();
        for(WR_BPM__Flow_Instance_History__c hist :histList)
            chatterPostList.add(getInfo(historyMap.get(hist.Id), (oldHistMap != null ? oldHistMap.get(hist.Id) : null)));
            
        getMaps();
        postChatter();
    }
    
    public void postChatter(){
        
        if(chatterPostList != null &&  !chatterPostList.isEmpty()){
           
           List<ConnectApi.BatchInput> batchInputs = new List<ConnectApi.BatchInput>();
           if(cpMap != null && !cpMap.isEmpty()){
                for(ChatterPostInfo post :chatterPostList){
                    if(cpMap.containsKey(post.recordId)){
                        ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();
                        ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
                        messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
                        if(post.assignedToId != null){
                            ConnectApi.MentionSegmentInput mentionAssignee = new ConnectApi.MentionSegmentInput();
                            mentionAssignee.Id = post.assignedToId;
                            messageBodyInput.messageSegments.add(mentionAssignee);
                        }
                        if(amMap != null && amMap.containsKey(cpMap.get(post.recordId).Id) && post.assignedToId != amMap.get(cpMap.get(post.recordId).Id)){
                            ConnectApi.MentionSegmentInput mentionAm = new ConnectApi.MentionSegmentInput();
                            mentionAm.Id = amMap.get(cpMap.get(post.recordId).Id);
                            messageBodyInput.messageSegments.add(mentionAm);
                        }
                        if(emMap != null && emMap.containsKey(cpMap.get(post.recordId).Id) && post.assignedToId != emMap.get(cpMap.get(post.recordId).Id)){
                            ConnectApi.MentionSegmentInput mentionEm = new ConnectApi.MentionSegmentInput();
                            mentionEm.Id = emMap.get(cpMap.get(post.recordId).Id);
                            messageBodyInput.messageSegments.add(mentionEm);
                        }
                        feedItemInput.subjectId = cpMap.get(post.recordId).Id;
                        ConnectApi.TextSegmentInput textSegment = new ConnectApi.TextSegmentInput();
                        textSegment.text = getPostBody(post);
                        messageBodyInput.messageSegments.add(textSegment);
                        feedItemInput.body = messageBodyInput;
                        if(post.type == 'Issue'){
                            ConnectApi.LinkCapabilityInput linkCapabilityInput = new ConnectApi.LinkCapabilityInput();
                            linkCapabilityInput.url = WorkRelayUtil.getProceedUrl(post.type, post.recordId, post.stepId);
                            linkCapabilityInput.urlName = post.Name;
                            ConnectApi.FeedElementCapabilitiesInput feedElementCapabilitiesInput = new ConnectApi.FeedElementCapabilitiesInput();
                            feedElementCapabilitiesInput.link = linkCapabilityInput;
                            feedItemInput.capabilities = feedElementCapabilitiesInput;
                        }
                        batchInputs.add(new ConnectApi.BatchInput(feedItemInput));
                    }  
                }
           }
           if(!batchInputs.isEmpty())
                ConnectApi.ChatterFeeds.postFeedElementBatch(Network.getNetworkId(), batchInputs);
        }
        
    }
    
    private ChatterPostInfo getInfo(WR_BPM__Flow_Instance_Issue__c iss, WR_BPM__Flow_Instance_Issue__c oldIss){
        
        ChatterPostInfo inf = new ChatterPostInfo();
        inf.recordId = iss.Id;
        inf.assignedToId = iss.WR_BPM__Assign_To__c;
        inf.objectType = iss.WR_BPM__Flow_Instance__r.WR_BPM__Object_Type__c;
        inf.objectId = (Id)iss.WR_BPM__Flow_Instance__r.WR_BPM__Object_Id__c;
        inf.cpId = iss.CampaignProfile__c;
        inf.Name = iss.Name;
        inf.type = 'Issue';
        inf.wrStatus = iss.WR_BPM__Status__c;
        inf.newRecord = true;
        if(oldIss != null){
            inf.newRecord = false;
            inf.oldAssignedToId = oldIss.WR_BPM__Assign_To__c;
            inf.oldWrStatus = oldIss.WR_BPM__Status__c;
        }
        return inf;
    }
    
    private ChatterPostInfo getInfo(WR_BPM__Flow_Instance_Cursor__c cur, WR_BPM__Flow_Instance_Cursor__c oldCur){
        
        ChatterPostInfo inf = new ChatterPostInfo();
        inf.recordId = cur.Id;
        inf.assignedToId = getAssignedTo(cur.WR_BPM__Step_Assigned_To__c);
        inf.objectType = cur.WR_BPM__Flow_Instance__r.WR_BPM__Object_Type__c;
        inf.objectId = (Id)cur.WR_BPM__Flow_Instance__r.WR_BPM__Object_Id__c;
        inf.cpId = cur.WR_BPM__Flow_Instance__r.Campaign_Profile__c;
        inf.Name = cur.WR_BPM__Step__r.Name;
        inf.type = 'Task';
        inf.newRecord = true;
        inf.stepId = cur.WR_BPM__Step__c; 
        if(oldCur != null){
            inf.newRecord = false;
            inf.oldAssignedToId = getAssignedTo(oldCur.WR_BPM__Step_Assigned_To__c);
        }
        return inf;
    }
    
    private ChatterPostInfo getInfo(WR_BPM__Flow_Instance_History__c hist, WR_BPM__Flow_Instance_History__c oldHist){
        
        ChatterPostInfo inf = new ChatterPostInfo();
        inf.recordId = hist.Id;
        inf.assignedToId = getAssignedTo(hist.WR_BPM__Assigned_To__c);
        inf.objectType = hist.WR_BPM__Cursor__r.WR_BPM__Flow_Instance__r.WR_BPM__Object_Type__c;
        inf.objectId = (Id)hist.WR_BPM__Cursor__r.WR_BPM__Flow_Instance__r.WR_BPM__Object_Id__c;
        inf.cpId = hist.WR_BPM__Cursor__r.WR_BPM__Flow_Instance__r.Campaign_Profile__c;
        inf.Name = hist.WR_BPM__Step__r.Name;
        inf.type = 'Task';
        inf.newRecord = true;
        inf.stepId = hist.WR_BPM__Step__c; 
        inf.completedDate = hist.WR_BPM__Completed_Date__c.format();
        if(oldHist != null){
            inf.newRecord = false;
            inf.oldAssignedToId = getAssignedTo(oldHist.WR_BPM__Assigned_To__c);
        }
        return inf;
    }
    
    public String getPostBody(ChatterPostInfo post){
        String rtn;
        rtn = post.type + ' ' + post.Name;
        if(post.newRecord == true){
            rtn = rtn + ' has been created';
        } else {
            //assignment changed
            if(post.assignedToId != post.oldAssignedToId){
                rtn = rtn + ' has been reassigned ';
                if(assignedMap != null && !assignedMap.isEmpty()){
                    if(post.oldAssignedToId != null && assignedMap.containsKey(post.oldAssignedToId))
                        rtn = rtn + ' from ' + assignedMap.get(post.oldAssignedToId).Name;
                    if(post.assignedToId != null && assignedMap.containsKey(post.assignedToId))
                        rtn = rtn + ' to ' + assignedMap.get(post.assignedToId).Name;
                    
                }
                rtn = rtn + '. ';
            }
            //status changed
            if(post.wrStatus != post.oldWrStatus)
                rtn = rtn + ' status has been changed from ' + post.oldWrStatus + ' to ' + post.wrStatus;
            if(post.completedDate != null)
                rtn = rtn + ' completed on ' + post.completedDate; 
        }
        return rtn;
    }

    
    private void getMaps(){
        
        Set<Id> cpIdSet = new Set<Id>();
        Map<Id, Id> crIdMap = new Map<Id, Id>();
        Set<Id> userSet = new Set<Id>();
        
        cpMap = new Map<Id, Campaign_Profile__c>();
        for(ChatterPostInfo post :chatterPostList){
            if(post.assignedToId != null)
                userSet.add(post.assignedToId);
            if(post.oldAssignedToId != null)
                  userSet.add(post.oldAssignedToId);
            if(post.objectType == campaignProfileObjectType){
                cpMap.put(post.recordId, new Campaign_Profile__c(Id = post.objectId));
                cpIdSet.add(post.objectId);
            }
            else if(post.objectType == changeRequestObjectType)
                crIdMap.put(post.objectId, post.recordId);
            else if(post.objectType == caseObjectType && post.cpId != null){
                cpMap.put(post.recordId, new Campaign_Profile__c(Id = post.cpId));
                cpIdSet.add(post.cpId);
            }
        }
        if(crIdMap != null && !crIdMap.isEmpty()){
            List<Change_Request__c> crList = new List<Change_Request__c>([Select Id, Campaign_Profile__c
                                                                          from Change_Request__c
                                                                           where Id IN :crIdMap.keySet()]);  
            if(crList != null && !crList.isEmpty()){
                for(Change_Request__c cr :crList){
                    cpMap.put(crIdMap.get(cr.Id), new Campaign_Profile__c(Id = cr.Campaign_Profile__c));
                    cpIdSet.add(cr.Campaign_Profile__c);
                }
            }
        }
        if(cpIdSet != null && !cpIdSet.isEmpty()){
            List<Campaign_Profile__c> cpList = new List<Campaign_Profile__c>([Select Id, (Select Id, Role__c, User__c from Campaign_Swimlanes_Assignments__r 
                                                                                          where User__c <> null and (Role__c = :amRole or Role__c = :emRole))
                                                                           from Campaign_Profile__c 
                                                                           where Id IN :cpIdSet]);
            if(cpList != null && !cpList.isEmpty()){
                amMap = new Map<Id, Id>();
                emMap = new Map<Id, Id>();
                for(Campaign_Profile__c cp :cpList){
                    if(cp.Campaign_Swimlanes_Assignments__r != null && !cp.Campaign_Swimlanes_Assignments__r.isEmpty()){
                        for(Campaign_Role_Assignment__c cra :cp.Campaign_Swimlanes_Assignments__r){
                            if(cra.Role__c == amRole)
                                amMap.put(cp.Id, cra.User__c);
                            if(cra.Role__c == emRole)
                                emMap.put(cp.Id, cra.User__c);
                        }
                    }
                        
                }
            }
        }
        if(userSet != null && !userSet.isEmpty())
            assignedMap = new Map<Id, User>([Select Id, Name
                                             from User
                                             where Id IN :userSet]);
        
    }
    
    private Id getAssignedTo(String assigned){
        
        Id assignedTo;
        String coma = ',';
        //get first id if more then one.
        if(assigned != null){
            Integer result = assigned.indexOf(coma);
            if(result != -1){
                assigned = assigned.substring(0, result);
            }
        }
        try{
            assignedTo = assigned;
        } catch (Exception e){}
        return assignedTo;
        
    }

}