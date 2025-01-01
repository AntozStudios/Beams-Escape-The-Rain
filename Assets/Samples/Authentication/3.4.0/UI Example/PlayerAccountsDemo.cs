using System;
using System.Collections.Generic;
using System.Text;
using System.Threading.Tasks;
using Unity.Services.CloudSave;
using Unity.Services.Core;
using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.UI;

namespace Unity.Services.Authentication.PlayerAccounts.Samples
{
    class PlayerAccountsDemo : MonoBehaviour
    {
        [SerializeField]
        Text m_StatusText;
        [SerializeField]
       
        
        public GameObject m_SignOut;
        [SerializeField]
       

        string m_ExternalIds;

        public static int loadLevel;

        async void Awake()
        {
            await UnityServices.InitializeAsync();
            PlayerAccountService.Instance.SignedIn +=  SignInWithUnity;

            if(AuthenticationService.Instance.SessionTokenExists){
                await SignInAnonymouslyAsync();
                SynchronizeHighScore();
               
            }


         
        }
async Task SignInAnonymouslyAsync()
{
    try
    {

        
        await AuthenticationService.Instance.SignInAnonymouslyAsync();
        Debug.Log("Sign in anonymously succeeded!");
        
        // Shows how to get the playerID
        Debug.Log($"PlayerID: {AuthenticationService.Instance.PlayerId}"); 

    }
    catch (AuthenticationException ex)
    {
        // Compare error code to AuthenticationErrorCodes
        // Notify the player with the proper error message
        Debug.LogException(ex);
    }
    catch (RequestFailedException ex)
    {
        // Compare error code to CommonErrorCodes
        // Notify the player with the proper error message
        Debug.LogException(ex);
     }
     UpdateUI();
}


        public async void StartSignInAsync()
        {
            if (PlayerAccountService.Instance.IsSignedIn)
            {
                SignInWithUnity();
                return;
            }

            try
            {
                await PlayerAccountService.Instance.StartSignInAsync();
            }
            catch (RequestFailedException ex)
            {
                Debug.LogException(ex);
           
            }
        }

        public void SignOut()
        {
            AuthenticationService.Instance.SignOut();
                AuthenticationService.Instance.ClearSessionToken();
                PlayerAccountService.Instance.SignOut();
        

           m_StatusText.text ="logged out";
        }

        public void OpenAccountPortal()
        {
            Application.OpenURL(PlayerAccountService.Instance.AccountPortalUrl);
        }

        async void SignInWithUnity()
        {
            try
            {
                await AuthenticationService.Instance.SignInWithUnityAsync(PlayerAccountService.Instance.AccessToken);
                m_ExternalIds = GetExternalIds(AuthenticationService.Instance.PlayerInfo);
                
            }
            catch (RequestFailedException ex)
            {
                Debug.LogException(ex);
       
            }
            UpdateUI();
        }

        void UpdateUI()
        {
            var statusBuilder = new StringBuilder();
         

            if (AuthenticationService.Instance.IsSignedIn)
            {
                m_SignOut.SetActive(true);
                statusBuilder.AppendLine(GetPlayerInfoText());
                statusBuilder.AppendLine($"PlayerId: <b>{AuthenticationService.Instance.PlayerId}</b>");
            }

            m_StatusText.text = statusBuilder.ToString();
           
        }

        string GetExternalIds(PlayerInfo playerInfo)
        {
            if (playerInfo.Identities == null)
            {
                return "None";
            }

            var sb = new StringBuilder();
            foreach (var id in playerInfo.Identities)
            {
                sb.Append(" " + id.TypeId);
            }

            return sb.ToString();
        }

        string GetPlayerInfoText()
        {
            return $"ExternalIds: <b>{m_ExternalIds}</b>";
        }

       public static async void SavePlayerData(string v, int currentLevel)
{
    var data = new Dictionary<string, object>
    {
        { "HighScore", currentLevel }
    };

    await CloudSaveService.Instance.Data.ForceSaveAsync(data);
}

public static async Task  LoadPlayerData()
{
    var savedData = await CloudSaveService.Instance.Data.LoadAllAsync();

    if (savedData.ContainsKey("HighScore"))
    {
        string highScoreString = savedData["HighScore"].ToString();
        int loadLevel = int.Parse(highScoreString);

        // Speichere den HighScore lokal
        PlayerAccountsDemo.loadLevel = loadLevel; // Globale Variable
        PlayerPrefs.SetInt("HighScore", loadLevel); // PlayerPrefs aktualisieren

        Debug.Log("Loaded HighScore: " + loadLevel);
    }else{
        SavePlayerData("HighScore",PlayerPrefs.GetInt("HighScore",0));
    }
}


public static async Task<bool> containsHighScoreAsync(){
    var savedData = await CloudSaveService.Instance.Data.LoadAllAsync();
    return savedData.ContainsKey("HighScore");
}

public static async Task UpdateHighScore(int newScore)
{
    var data = new Dictionary<string, object>
    {
        { "HighScore", newScore }
    };

    await CloudSaveService.Instance.Data.ForceSaveAsync(data);

    Debug.Log("HighScore updated to: " + newScore);
}

public static async void SynchronizeHighScore()
{
    // Lade Cloud-Daten
    await LoadPlayerData();

    // Lokalen HighScore abrufen
    int localHighScore = PlayerPrefs.GetInt("HighScore");

    // Synchronisation zwischen Cloud und Lokal
    if (PlayerAccountsDemo.loadLevel > localHighScore)
    {
        PlayerPrefs.SetInt("HighScore", PlayerAccountsDemo.loadLevel);
        Debug.Log("Local HighScore updated to: " + PlayerAccountsDemo.loadLevel);
    }
    else if (localHighScore > PlayerAccountsDemo.loadLevel)
    {
        await UpdateHighScore(localHighScore);
        Debug.Log("Cloud HighScore updated to: " + localHighScore);
    }
}


    }
    

    

    
    
}



