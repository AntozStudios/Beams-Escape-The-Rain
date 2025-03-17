using System;
using System.Collections.Generic;
using System.Text;
using System.Threading.Tasks;
using NUnit.Framework;
using TMPro;
using Unity.Services.CloudSave;
using Unity.Services.Core;
using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.UI;

namespace Unity.Services.Authentication.PlayerAccounts.Samples
{
    class PlayerAccountsDemo : MonoBehaviour
    {
        [SerializeField] TMP_Text playerID;
        [SerializeField] Button signInButton, signOutButton;

        public static PlayerAccountsDemo Instance;

        string m_ExternalIds;
        public int loadLevel;

        [SerializeField] ArchivementManager archivementManager;

      async void Awake()
{
    await UnityServices.InitializeAsync();

    PlayerAccountService.Instance.SignedIn += SignInWithUnity;

    // Überprüfen, ob der Benutzer bereits angemeldet ist
    if (AuthenticationService.Instance.IsSignedIn)
    {
        Debug.Log("User is already signed in.");
        SignInWithUnity(); // Aktualisiere den Status und die UI
    }
    else if (AuthenticationService.Instance.SessionTokenExists)
    {
        Debug.Log("Session token exists, signing in anonymously.");
        await SignInAnonymouslyAsync();
    }
    else
    {
        Debug.Log("No session token, user is not signed in.");
        UpdateUI();
    }
}


        void Update()
        {
            
            // UI nur aktualisieren, wenn sich der Login-Status geändert hat
            UpdateUI();
        }

        async Task SignInAnonymouslyAsync()
        {
            try
            {
                await AuthenticationService.Instance.SignInAnonymouslyAsync();
                Debug.Log("Sign in anonymously succeeded!");
                
            }
            catch (RequestFailedException ex)
            {
                Debug.LogError($"Anonymous sign-in failed: {ex.Message}");
            }
        }

        // Seite wird gestartet
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
                Debug.Log("Sign-in initiated successfully");
            }
            catch (RequestFailedException ex)
            {
                Debug.LogError($"Sign-in failed: {ex.Message}");
            }
        }

        public void SignOut()
        {
            PlayerAccountService.Instance.SignOut();
            AuthenticationService.Instance.SignOut(true);
            AuthenticationService.Instance.ClearSessionToken();
            

            playerID.text = "logged out";
            PlayerPrefs.SetString("PlayMode", "Local");
            PlayerPrefs.SetInt("HighScore",0);

            archivementManager.ResetSavedItems();
        }

        async void SignInWithUnity()
        {
            try
            {
                await AuthenticationService.Instance.SignInWithUnityAsync(PlayerAccountService.Instance.AccessToken);
                m_ExternalIds = GetExternalIds(AuthenticationService.Instance.PlayerInfo);

               
            
                await SynchronizeHighScoreAsync();  // Synchronisiere den Highscore nach der Anmeldung
            }
            catch (AuthenticationException ex)
            {
               Debug.Log($"Authentication failed with code: {ex.ErrorCode}, message: {ex.Message}");

            }
        }

        void UpdateUI()
        {
            if (AuthenticationService.Instance.IsSignedIn)
            {
                signInButton.interactable = false;
                signOutButton.interactable = true;
                playerID.text = $"PlayerId: <b>{AuthenticationService.Instance.PlayerId}</b>";
            }
            else
            {
                signInButton.interactable = true;
                signOutButton.interactable = false;
                playerID.text = "logged out";
            }
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

        

        public async Task SynchronizeHighScoreAsync()
        {
            await LoadPlayerDataAsync();
            
            PlayerPrefs.SetString("PlayMode", "Cloud");

            int localHighScore = PlayerPrefs.GetInt("HighScore");
            Debug.Log(localHighScore);

            if (localHighScore > loadLevel)
            {
                await UpdateHighScoreAsync(localHighScore);
                Debug.Log("Highscore updated, Local Highscore was higher");
            }
            else
            {
                PlayerPrefs.SetInt("HighScore", loadLevel);
                Debug.Log("Highscore updated, Cload Highscore was higher");
            }
        }

        public async Task LoadPlayerDataAsync()
        {
            var savedData = await CloudSaveService.Instance.Data.LoadAllAsync();

            if (savedData.ContainsKey("HighScore"))
            {
                string highScoreString = savedData["HighScore"].ToString();
                loadLevel = int.Parse(highScoreString);
                Debug.Log("Loaded HighScore: " + loadLevel);
            
            }
            else
            {
                await SavePlayerDataAsync("HighScore", PlayerPrefs.GetInt("HighScore", 0));
            }
        }

        public async Task SavePlayerDataAsync(string key, int value)
        {
            var data = new Dictionary<string, object>
            {
                { key, value }
            };

            await CloudSaveService.Instance.Data.ForceSaveAsync(data);
        }

        public async Task UpdateHighScoreAsync(int newScore)
        {
            var data = new Dictionary<string, object>
            {
                { "HighScore", newScore }
            };

            await CloudSaveService.Instance.Data.ForceSaveAsync(data);
            Debug.Log("HighScore updated to: " + newScore);
        }

        private bool firstLogin()
        {
            return string.IsNullOrEmpty(PlayerPrefs.GetString("LastPlayerID"));
        }
    }
}
