trigger contacttrigger on Contact (before insert) {
    if(Trigger.isBefore){
        Double roundRobinValue=1;
        List<Contact> conList=[SELECT Id, Round_Robin_ID__c, CreatedDate FROM Contact WHERE Round_Robin_ID__c !=null order by CreatedDate desc limit 1];
   
        if(conList !=null && conList.size()>0){
            roundRobinValue= conList[0].Round_Robin_ID__c;
        }
        for(Contact c:Trigger.New){
            System.debug('###Round Robin Value :' +roundRobinValue);
            if(roundRobinValue==3){
                roundRobinValue=1;
                c.OwnerId='0054P00000AFn5oQAD';
            }
            else if(roundRobinValue==2){
                roundRobinValue++;
                c.OwnerId='0054P00000AQOkZQAX';
            }
            else{
                roundRobinValue++;
                c.OwnerId='0054P00000BYhRqQAL';
            }
            c.Round_Robin_ID__c=roundRobinValue;
        }
    }

}