using UnityEngine;

public class LinkContainer: MonoBehaviour
{

    public  string linkToTermsOfService="https://github.com/AntozStudios/Beams.terms.of.service.io";
    public  string linkToPolicy="https://github.com/AntozStudios/Beams.privacy.policy.io";

    public string linkToPolicyOfUnity ="https://unity.com/legal/privacy-policy";
    public string playStoreLink="https://play.google.com/store/apps/details?id=com.AntozStudios.BeamsEscapeTheRain&hl=de";
    public string unityPortalLink="https://player-account.unity.com/";




public void OpenLink(string link){
Application.OpenURL(link);
}
    
}
