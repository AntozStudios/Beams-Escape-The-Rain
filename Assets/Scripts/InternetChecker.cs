using UnityEngine;

public class InternetChecker : MonoBehaviour
{
    
    void Start()
    {
        if (IsInternetAvailable())
        {
            Debug.Log("Internet ist verfügbar.");
        }
        else
        {
            Debug.Log("Kein Internet verfügbar.");
        }
    }

    bool IsInternetAvailable()
    {
        return Application.internetReachability != NetworkReachability.NotReachable;
    }
}
