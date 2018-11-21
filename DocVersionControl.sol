pragma solidity ^0.4.10;

contract DocVersionControl { 
    
    // Variables
  address public approvers;address public developer1;
  address public allapprovers;
  uint  numberOfUploads;uint  numberOfApprovals; 
  uint numberOfRequestsByDevelopers; uint  numberOfNewRequests;
  string public documentInfo; 
  string IPFShashForDocument;
  
    enum contractState {NotReady, Created, WaitForApproversSignature,
    SignatureProvided,SignatureDenied,NewRegRequested,
    RegRequestGranted,RegRequestDenied}
    contractState public contState; 
    enum developerState {ReadyToSubmit, SubmittedForApproval,
    ApprovalProvided,ApprovalNotProvided}
    developerState public devState;
    enum approverState {WaitingToSign, ApprovalSuccess ,
    ApprovalFailed, NewApprovalsSuccess,NewApprovalsFailed}
    approverState public apprState;
    enum newRegistrationState {WaitToRegister,NewRegistrationRequested, 
    GrantSuccess, RegFailure}
    newRegistrationState public newRegState;
 
      // mappings 
    mapping(address => bool) public docVersions;// versions 
   mapping(address=>string) public documentHashes; //hashes for the Doc of different version
    mapping (address=>developerState) public developers; mapping(address=>newRegistrationState) public newEntry;
    
      // modifiers
       modifier OnlyApprover{ 
         require(msg.sender == approvers);
         _;
         }
     modifier NotApprover{ 
         require(msg.sender != approvers);
         _;
         }
       modifier OnlyDeveloper1{
            require(msg.sender==developer1);
            _;
        }
        modifier NotDeveloper1{
            require(msg.sender!=developer1);
            _;}
            
        modifier AllApprovers{ 
                require(msg.sender==allapprovers); 
                _;
            }
       
    //events
    event ContractCreated(address owner, string info);
    event DocumentUploaded(address developer1, string info);
    event ApprovalRequested(address approvers, string info);
    event NewVersionSigned(address regdApprovers, string info);
    event ApprovalGranted(address regdApprovers, string info);
    event SignatureNotProvidedbyAll (address regdApprovers, string info);
    event ApprovalRejected(address regdApprovers, string info);
    event NewRegistrationRequested(address owner, string info);
    event ApprovedSuccess(address receiver, string msg, address developers, address regdApprovers); //contract is verified and agreed with
    event DenyRequest(address receiver,string msg);
    
    //constructor
    function DocVersionControl() payable {
    documentInfo = "Document : Version 1.0";
    approvers= msg.sender;
    IPFShashForDocument= "QmXgm5QVTy8pRtKrTPmoWPGXNesehCpP4jjFMTpvGamc1p";
    contState = contractState.NotReady;
    devState=developerState.ReadyToSubmit;
    apprState=approverState.WaitingToSign;
    newRegState=newRegistrationState.WaitToRegister;
    developer1= 0x14723a09acff6d2a60dcdf7aa4aff308fddc160c;
    numberOfApprovals = 0; numberOfUploads = 0;
    numberOfNewRequests=0; numberOfRequestsByDevelopers=0;
  }
//functions 
function createContract()OnlyApprover public {
  require(contState == contractState.NotReady);
  contState = contractState.Created;
  ContractCreated(msg.sender, "Smart Contract created by Approver A1.");
}

/* offline -----> developer adds document on IPFS */
 
function requestForApproval(address developerAddress, string documentHash) NotApprover  public {
 require(contState==contractState.Created && developers[developerAddress] == developerState.ReadyToSubmit);
  developers[developerAddress] = developerState.SubmittedForApproval;
  contState = contractState.WaitForApproversSignature;
  documentHashes[developerAddress] = documentHash; //update mapping
  devState=developerState.SubmittedForApproval;
  ApprovalRequested(msg.sender, " Signature awaited from 'all' or atleast by '2/3rd' of approvers to update Version 1.0 on IPFS ");
  numberOfUploads +=1;
  numberOfRequestsByDevelopers+=1;
}
function provideApprovalToUpload(address developerAddress) OnlyApprover  public {
 require(contState==contractState.WaitForApproversSignature && (developers[developerAddress]==developerState.SubmittedForApproval));
 require( apprState==approverState.WaitingToSign);
  
 if(keccak256(documentHashes[developerAddress]) == keccak256(IPFShashForDocument)) {
 developers[developerAddress]= developerState.ApprovalProvided;
 contState=contractState.SignatureProvided;
 NewVersionSigned(msg.sender, "Document Version 1.0 : Approved by all or atleast 2/3rd of Registered Approvers in the Chain");
 docVersions[developerAddress]=true;
 apprState=approverState.ApprovalSuccess;
 devState=developerState.ApprovalProvided;
 numberOfApprovals +=1;
 ApprovalGranted(developerAddress, "Request Granted: Publish the new Version on IPFS.");  }
 
 else if(keccak256(documentHashes[developerAddress])!= keccak256(IPFShashForDocument)) {
     
 developers[developerAddress]= developerState.ApprovalNotProvided;
  contState=contractState.SignatureDenied;
 SignatureNotProvidedbyAll(msg.sender, "Document not approved by even 2/3rd of Registered Approvers");
 docVersions[developerAddress]=false;
  apprState=approverState.ApprovalFailed;
 ApprovalRejected(developerAddress, " Not Allowed to modify existing version.");
 devState=developerState.ApprovalNotProvided; }
}
function requestNewRegistration(address newEntryAddress)NotDeveloper1 public {
require(contState==contractState.SignatureProvided && newEntry[newEntryAddress]==newRegistrationState.WaitToRegister);

   newEntry[newEntryAddress]==newRegistrationState.NewRegistrationRequested;
   contState=contractState.NewRegRequested;
   newRegState=newRegistrationState.NewRegistrationRequested;
   numberOfNewRequests+=1;
   NewRegistrationRequested(msg.sender, "Grant approval / permission to register as a new entity.");}
    
function voteToApprove(address newEntryAddress, address developers, address regdApprovers ,bool result) public {
require(contState == contractState.NewRegRequested || apprState==approverState.WaitingToSign );

if(result==true){
  contState=contractState.RegRequestGranted;
  ApprovedSuccess(newEntryAddress, "Permission granted to register by:", developers, regdApprovers);
  newRegState=newRegistrationState.GrantSuccess;
  apprState=approverState.NewApprovalsSuccess;
}
 else if(result==false) {
       contState=contractState.RegRequestDenied;
       DenyRequest(newEntryAddress,"Registration Denied.");
       newRegState=newRegistrationState.RegFailure; //apprState=approverState.NewApprovalsSuccess;
       apprState=approverState.NewApprovalsFailed;}
  }
    
}
