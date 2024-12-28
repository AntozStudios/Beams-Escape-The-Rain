using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

using TMPro;
using GoogleMobileAds;
using GoogleMobileAds.Api;
using GoogleMobileAds.Ump.Api;
using System;
using UnityEngine.SceneManagement;




// Ads will be initialzied



public class AdManager : MonoBehaviour
{

  [SerializeField] GameObject player;
  [SerializeField] Button adButton;

  [SerializeField] LevelManager levelManager;
  private int adUsed;
  [SerializeField] bool isTesting;
  private const int MAX_ADS = 3;
 

  private string _adUnitId;


  
  private RewardedInterstitialAd  _rewardedInitAd;
    public void Awake()
    {

      // Create a ConsentRequestParameters object.
    ConsentRequestParameters request = new ConsentRequestParameters();

    // Check the current consent information status.
    ConsentInformation.Update(request, OnConsentInfoUpdated);
if(isTesting){
  _adUnitId ="ca-app-pub-3940256099942544/5354046379";
}else{
_adUnitId = "ca-app-pub-1320039869895590/5136125260";
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
              
        
        LoadInterstitialAd();
            });
        }
    });
}

   private void LoadInterstitialAd()
{
    if (_rewardedInitAd != null)
    {
        _rewardedInitAd.Destroy();
        _rewardedInitAd = null;
    }

    Debug.Log("Lade neue Rewarded-Interstitial-Anzeige...");

    var adRequest = new AdRequest();

    RewardedInterstitialAd.Load(_adUnitId, adRequest,
        (RewardedInterstitialAd ad, LoadAdError error) =>
        {
            if (error != null || ad == null)
            {
                Debug.LogError("Anzeige konnte nicht geladen werden: " + error);
                return;
            }

            Debug.Log("Anzeige erfolgreich geladen.");
            _rewardedInitAd = ad;

            // Registriere Events
            RegisterEventHandlers(_rewardedInitAd);
        });
}

    /// <summary>
    /// Loads the rewarded ad.
    /// </summary>
   


public void ShowRewardedInterstitialAd()
{
    if (_rewardedInitAd != null && _rewardedInitAd.CanShowAd())
    {
        _rewardedInitAd.Show((Reward reward) =>
        {
            Debug.Log($"Belohnung erhalten: {reward.Type}, Menge: {reward.Amount}");
            // Belohnungslogik hier
            player.GetComponent<PlayerCollision>().amountLife += (int)reward.Amount;
            player.GetComponent<PlayerCollision>().revivePlayer();
            levelManager.setPlayerToStartTop();
            adUsed++;
        });
    }
    else
    {
        Debug.LogWarning("Anzeige nicht bereit. Versuche, neu zu laden...");
        LoadInterstitialAd();
    }
}


public void Update(){
    adButton.gameObject.SetActive(adUsed<MAX_ADS);
    

}

private void RegisterEventHandlers(RewardedInterstitialAd ad)
{
    // Raised when the ad is estimated to have earned money.
    ad.OnAdPaid += (AdValue adValue) =>
    {
      //  Debug.Log(String.Format("Rewarded interstitial ad paid {0} {1}.",
          //  adValue.Value,
          //  adValue.CurrencyCode));
    };
    // Raised when an impression is recorded for an ad.
    ad.OnAdImpressionRecorded += () =>
    {
      ///  Debug.Log("Rewarded interstitial ad recorded an impression.");
    };
    // Raised when a click is recorded for an ad.
    ad.OnAdClicked += () =>
    {
       // Debug.Log("Rewarded interstitial ad was clicked.");
    };
    // Raised when an ad opened full screen content.
    ad.OnAdFullScreenContentOpened += () =>
    {
       // Debug.Log("Rewarded interstitial ad full screen content opened.");
    };
    // Raised when the ad closed full screen content.
    ad.OnAdFullScreenContentClosed += () =>
    {
      //  Debug.Log("Rewarded interstitial ad full screen content closed.");
      LoadInterstitialAd();
        
    };
    // Raised when the ad failed to open full screen content.
    ad.OnAdFullScreenContentFailed += (AdError error) =>
    {
       // Debug.LogError("Rewarded interstitial ad failed to open " +
                 //      "full screen content with error : " + error);
                 LoadInterstitialAd();
    };
    
}

  
}