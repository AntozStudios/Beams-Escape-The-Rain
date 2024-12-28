using System.Threading.Tasks;
using GooglePlayGames;
using GooglePlayGames.BasicApi;
using Unity.Services.Authentication;
using Unity.Services.Core;
using UnityEngine;

public class GoogleIntegration : MonoBehaviour
{
    //CgkIgfWTvrYGEAIQAg
    
    public string GooglePlayToken;
    public string GooglePlayError;

    public async Task Authenticate()
    {
        PlayGamesPlatform.Activate();
        await UnityServices.InitializeAsync();
        
        PlayGamesPlatform.Instance.Authenticate((success) =>
        {
            if (success == SignInStatus.Success)
            {
                Debug.Log("Login with Google was successful.");
                PlayGamesPlatform.Instance.RequestServerSideAccess(true, code =>
                {
                    Debug.Log($"Auth code is {code}");
                    GooglePlayToken = code;
                });
            }
            else
            {
                GooglePlayError = "Failed to retrieve GPG auth code";
                Debug.LogError("Login Unsuccessful");
            }
        });

        await AuthenticateWithUnity();
    }

    private async Task AuthenticateWithUnity()
    {
        try
        {
            await AuthenticationService.Instance.SignInWithGoogleAsync(GooglePlayToken);
        }
        catch (AuthenticationException ex)
        {
            Debug.LogException(ex);
            throw;
        }
        catch (RequestFailedException ex)
        {
            Debug.LogException(ex);
            throw;
        }
    }

    public void ShowLeaderBoard()
{
    if (PlayGamesPlatform.Instance.IsAuthenticated())
    {
        PlayGamesPlatform.Instance.ShowLeaderboardUI();
    }
    else
    {
        Debug.LogError("Spieler ist nicht authentifiziert. Leaderboard kann nicht angezeigt werden.");
    }
}


public void PostHighScore(int score, string leaderboardId)
{
    if (PlayGamesPlatform.Instance.IsAuthenticated())
    {
        PlayGamesPlatform.Instance.ReportScore(score, leaderboardId, success =>
        {
            if (success)
            {
                Debug.Log("Highscore erfolgreich gepostet!");
            }
            else
            {
                Debug.LogError("Fehler beim Posten des Highscores.");
            }
        });
    }
    else
    {
        Debug.LogError("Spieler nicht authentifiziert. Kann Highscore nicht posten.");
    }
}





}