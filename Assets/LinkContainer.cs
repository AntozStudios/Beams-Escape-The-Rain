using UnityEngine;

public class LinkContainer: MonoBehaviour
{

    public  string linkToTermsOfService;
    public  string linkToPolicy;

    public string linkToPolicyOfUnity ;




public void OpenLink(string link){
Application.OpenURL(link);
}
    
}
