using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

using TMPro;
using GoogleMobileAds;
using GoogleMobileAds.Api;
using GoogleMobileAds.Ump.Api;




// Ads will be initialzied



public class AdManager : MonoBehaviour
{

  [SerializeField] GameObject player;
  [SerializeField] Button adButton;

  [SerializeField] LevelManager levelManager;
  private int adUsed;
  [SerializeField] bool isTesting;
  private const int MAX_ADS = 3;
  //ca-app-pub-1320039869895590/8143995197
//Test ID ca-app-pub-3940256099942544/5224354917
 
      // These ad units are configured to always serve test ads.

  private string _adUnitId;


  private RewardedAd _rewardedAd;
    public void Awake()
    {

      // Create a ConsentRequestParameters object.
    ConsentRequestParameters request = new ConsentRequestParameters();

    // Check the current consent information status.
    ConsentInformation.Update(request, OnConsentInfoUpdated);
if(isTesting){
  _adUnitId ="ca-app-pub-3940256099942544/5224354917";
}else{
_adUnitId = "ca-app-pub-1320039869895590/8143995197";
}
      
    }


    void OnConsentInfoUpdated(FormError consentError)
{
    if (consentError != null)
    {
        // Handle the error.
        UnityEngine.Debug.LogError(consentError);
        return;
    }

    // If the error is null, the consent information state was updated.
    // You are now ready to check if a form is available.
    ConsentForm.LoadAndShowConsentFormIfRequired((FormError formError) =>
    {
        if (formError != null)
        {
            // Consent gathering failed.
            UnityEngine.Debug.LogError(consentError);
            return;
        }

        
           // Consent has been gathered.
        if (ConsentInformation.CanRequestAds())
        {
            MobileAds.Initialize((InitializationStatus initstatus) =>
            {
              // Initialize the Google Mobile Ads SDK.
        MobileAds.Initialize((InitializationStatus initStatus) =>
        {
            LoadRewardedAd();
        });
            });
        }
    });
}

     /// <summary>
  /// Loads the rewarded ad.
  /// </summary>
  public void LoadRewardedAd()
  {
      // Clean up the old ad before loading a new one.
      if (_rewardedAd != null)
      {
            _rewardedAd.Destroy();
            _rewardedAd = null;
      }

      Debug.Log("Loading the rewarded ad.");
      

      // create our request used to load the ad.
      var adRequest = new AdRequest();

      // send the request to load the ad.
      RewardedAd.Load(_adUnitId, adRequest,
          (RewardedAd ad, LoadAdError error) =>
          {
              // if error is not null, the load request failed.
              if (error != null || ad == null)
              {
                  Debug.LogError("Rewarded ad failed to load an ad " +
                                 "with error : " + error);
                  return;
              }

              Debug.Log("Rewarded ad loaded with response : "
                        + ad.GetResponseInfo());

              _rewardedAd = ad;
              RegisterEventHandlers(_rewardedAd);
            
          });
  }

  public void ShowRewardedAd()
{
    const string rewardMsg =
        "Rewarded ad rewarded the user. Type: {0}, amount: {1}.";

    if (_rewardedAd != null && _rewardedAd.CanShowAd())
    {
        _rewardedAd.Show((Reward reward) =>
        {
            // TODO: Reward the user.
          //  Debug.Log(string.Format(rewardMsg, reward.Type, reward.Amount));
    
   
        player.GetComponent<PlayerCollision>().amountLife+=(int) reward.Amount;
        player.GetComponent<PlayerCollision>().revivePlayer();
        levelManager.setPlayerToStartTop();
        adUsed++;
    
      
        

        });
    }
    
}
public void Update(){
    adButton.gameObject.SetActive(adUsed<MAX_ADS);
    

}
private void RegisterEventHandlers(RewardedAd ad)
{
    // Raised when the ad is estimated to have earned money.
    ad.OnAdPaid += (AdValue adValue) =>
    {
     //   Debug.Log(string.Format("Rewarded ad paid {0} {1}.",adValue.Value,adValue.CurrencyCode));
    };
    // Raised when an impression is recorded for an ad.
    ad.OnAdImpressionRecorded += () =>
    {
        
      //  Debug.Log("Rewarded ad recorded an impression.");
    };
    // Raised when a click is recorded for an ad.
    ad.OnAdClicked += () =>
    {
       // Debug.Log("Rewarded ad was clicked.");
    };
    // Raised when an ad opened full screen content.
    ad.OnAdFullScreenContentOpened += () =>
    {
        //Debug.Log("Rewarded ad full screen content opened.");
    };
    // Raised when the ad closed full screen content.
    ad.OnAdFullScreenContentClosed += () =>
    {
      //  Debug.Log("Rewarded ad full screen content closed.");
        LoadRewardedAd();
    };
    // Raised when the ad failed to open full screen content.
    ad.OnAdFullScreenContentFailed += (AdError error) =>
    {
    ///    Debug.LogError("Rewarded ad failed to open full screen content " +"with error : " + error);
                       LoadRewardedAd();
    };
}
  
}