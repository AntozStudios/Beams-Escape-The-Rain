using System;
using System.Collections.Generic;
using System.Text;
using System.Threading.Tasks;
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
        [SerializeField] GameObject overwritePanel;
        bool areYouSure;
        
        [SerializeField] TMP_Text playerID;
        [SerializeField] Button signButton, signOut;

        public GameObject m_SignOut;

        public static PlayerAccountsDemo Instance;

        string m_ExternalIds;

        public int loadLevel;

        GameObject temp;

        async void Awake()
        {
            if (Instance == null)
            {
                Instance = this;
                DontDestroyOnLoad(gameObject);
            }
            else if (Instance != this)
            {
                Destroy(this);
                return;
            }

            await UnityServices.InitializeAsync();
            PlayerAccountService.Instance.SignedIn += SignInWithUnity;

            if (AuthenticationService.Instance.SessionTokenExists)
            {
                await SignInAnonymouslyAsync();
                
                if (!string.IsNullOrEmpty(PlayerPrefs.GetString("LastPlayerID")) &&
                    !string.IsNullOrEmpty(PlayerPrefs.GetString("CurrentPlayerID")) &&
                    !isSameUser())
                {
                    Debug.Log("Lokale Punkte werden auf 0 gesetzt, weil du dich mit einem anderen Konto angemeldet hast.");
                    PlayerPrefs.SetInt("HighScore", 0);
                }

                await SynchronizeHighScoreAsync();
                PlayerPrefs.SetString("CurrentAccessToken", AuthenticationService.Instance.PlayerId);
                signButton.gameObject.SetActive(false);
            }

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
                Debug.LogException(ex);
            }
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

            PlayerPrefs.SetString("OverWrite", "");
            PlayerPrefs.SetString("LastPlayerID", PlayerPrefs.GetString("CurrentPlayerID"));
            PlayerPrefs.SetString("CurrentPlayerID", string.Empty);

            playerID.text = "logged out";
            UpdateUI();
        }

        async void SignInWithUnity()
        {
            try
            {
                await AuthenticationService.Instance.SignInWithUnityAsync(PlayerAccountService.Instance.AccessToken);
                m_ExternalIds = GetExternalIds(AuthenticationService.Instance.PlayerInfo);

                PlayerPrefs.SetString("CurrentPlayerID", AuthenticationService.Instance.PlayerId);
                if (!isSameUser())
                {
                    Debug.Log("Lokale Punkte werden auf 0 gesetzt, weil du dich mit einem anderen Konto angemeldet hast.");
                    PlayerPrefs.SetInt("HighScore", 0);
                }

                await SynchronizeHighScoreAsync();
            }
            catch (AuthenticationException ex)
            {
                Debug.LogException(ex);
            }

            UpdateUI();
        }

        bool isSameUser()
        {
            string lastPlayerId = PlayerPrefs.GetString("LastPlayerID");
            string currentPlayerId = PlayerPrefs.GetString("CurrentPlayerID");
            return !string.IsNullOrEmpty(lastPlayerId) && lastPlayerId.Equals(currentPlayerId);
        }

        void UpdateUI()
        {
            var statusBuilder = new StringBuilder();

            if (AuthenticationService.Instance.IsSignedIn)
            {
                m_SignOut.SetActive(true);
                statusBuilder.AppendLine(GetPlayerInfoText());
                statusBuilder.AppendLine($"PlayerId: <b>{AuthenticationService.Instance.PlayerId}</b>");
                signOut.gameObject.SetActive(true);
                signButton.gameObject.SetActive(false);
                PlayerPrefs.SetString("PlayMode", "Cloud");
            }
            else
            {
                signButton.gameObject.SetActive(true);
                signOut.gameObject.SetActive(false);
                PlayerPrefs.SetString("PlayMode", "Local");
            }

            playerID.text = statusBuilder.ToString();
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

        public async Task SynchronizeHighScoreAsync()
        {
            await LoadPlayerDataAsync();

            int localHighScore = PlayerPrefs.GetInt("HighScore");
            // Lokale Punktzahl ist hoeher als  Cloud und das ist der selbe Spieleraccount
            if (loadLevel > localHighScore && !PlayerPrefs.GetString("OverWrite").Equals( "Asked") && isSameUser() )
            {
                temp = Instantiate(overwritePanel);
                temp.GetComponent<PopUp>().text.text = $"Profile level HighScore is: {loadLevel}, Your current HighScore is {localHighScore}";
                temp.GetComponentInChildren<Animator>().SetTrigger("start");

                temp.GetComponent<YesNoConfig>().yes.onClick.AddListener(async () =>
                {
                    temp.GetComponent<PopUp>().text.text="Are you sure?";
                    temp.GetComponent<YesNoConfig>().yes.onClick.RemoveAllListeners();
                  temp.GetComponent<YesNoConfig>().yes.onClick.AddListener(()=>areYouSureMethod());
                });
          
        

                temp.GetComponent<YesNoConfig>().no.onClick.AddListener(() =>
                {
                    PlayerPrefs.SetInt("HighScore", loadLevel);
                    PlayerPrefs.SetString("OverWrite", "Asked");
                    Destroy(temp);
                });

            // Spieleraccount wurde gewechselt und Spieleraccount existiert, ist nicht gleich wie der vorherige
            }else if (localHighScore > 0 && !PlayerPrefs.GetString("OverWrite").Equals( "Asked")&& !isSameUser() )
            {
                temp = Instantiate(overwritePanel);
                temp.GetComponent<PopUp>().text.text = $"Profile with highscore {loadLevel} loaded!";
                temp.GetComponentInChildren<Animator>().SetTrigger("start");

                temp.GetComponent<YesNoConfig>().yes.onClick.AddListener(async () =>
                {
                    PlayerPrefs.SetInt("HighScore", loadLevel);
                    PlayerPrefs.SetString("OverWrite", "Asked");
                    Destroy(temp);
                });
          
        

                temp.GetComponent<YesNoConfig>().no.gameObject.SetActive(false);


            }

           
            else if (loadLevel == 0)
            {
                PlayerPrefs.SetInt("HighScore", localHighScore);
                PlayerPrefs.SetString("OverWrite", "Asked");
            }
           
        }

        private  async void areYouSureMethod(){
            int localHighScore = PlayerPrefs.GetInt("HighScore");
            await UpdateHighScoreAsync(localHighScore);
                    PlayerPrefs.SetString("OverWrite", "Asked");
                    Destroy(temp);
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
    }
}
