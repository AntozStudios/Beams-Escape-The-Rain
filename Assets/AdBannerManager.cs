using GoogleMobileAds.Api;
using GoogleMobileAds.Ump.Api;
using UnityEngine;

public class AdBannerManager : MonoBehaviour
{
    [SerializeField] AdManager adManager;
   
   void Start(){


CreateBannerView();
ListenToAdEvents();
LoadAd();
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
              
        
        
            });
        }
    });
}

     public void CreateBannerView()
  {
      Debug.Log("Creating banner view");

      // If we already have a banner, destroy the old one.
      if (adManager._bannerView != null)
      {
          DestroyAd();
      }

      // Create a 320x50 banner at bottom of the screen
      AdSize adSize = new AdSize(320,50);
      adManager._bannerView = new BannerView(adManager.bannerID, adSize, AdPosition.Bottom);
  }

/// <summary>
/// Creates the banner view and loads a banner ad.
/// </summary>
public void LoadAd()
{
    // create an instance of a banner view first.
    if(adManager._bannerView == null)
    {
        CreateBannerView();
    }

    // create our request used to load the ad.
    var adRequest = new AdRequest();

    // send the request to load the ad.
    Debug.Log("Loading banner ad.");
    adManager._bannerView.LoadAd(adRequest);
}
    
/// <summary>
/// listen to events the banner view may raise.
/// </summary>
private void ListenToAdEvents()
{
    // Raised when an ad is loaded into the banner view.
    adManager._bannerView.OnBannerAdLoaded += () =>
    {
        Debug.Log("Banner view loaded an ad with response : "
            + adManager._bannerView.GetResponseInfo());
    };
    // Raised when an ad fails to load into the banner view.
    adManager._bannerView.OnBannerAdLoadFailed += (LoadAdError error) =>
    {
        Debug.LogError("Banner view failed to load an ad with error : "
            + error);
    };
    // Raised when the ad is estimated to have earned money.
    adManager._bannerView.OnAdPaid += (AdValue adValue) =>
    {
        Debug.Log(string.Format("Banner view paid {0} {1}.",
            adValue.Value,
            adValue.CurrencyCode));
    };
    // Raised when an impression is recorded for an ad.
    adManager._bannerView.OnAdImpressionRecorded += () =>
    {
        Debug.Log("Banner view recorded an impression.");
    };
    // Raised when a click is recorded for an ad.
    adManager._bannerView.OnAdClicked += () =>
    {
        Debug.Log("Banner view was clicked.");
    };
    // Raised when an ad opened full screen content.
    adManager._bannerView.OnAdFullScreenContentOpened += () =>
    {
        Debug.Log("Banner view full screen content opened.");
    };
    // Raised when the ad closed full screen content.
    adManager._bannerView.OnAdFullScreenContentClosed += () =>
    {
        Debug.Log("Banner view full screen content closed.");
        
    };
}

/// <summary>
/// Destroys the banner view.
/// </summary>
public void DestroyAd()
{
    if (  adManager._bannerView != null)
    {
        Debug.Log("Destroying banner view.");
          adManager._bannerView.Destroy();
          adManager._bannerView = null;
    }
}
}
