using UnityEngine;

public class Config : MonoBehaviour
{
    [SerializeField] GameObject player; // Nur behalten, wenn benötigt
    [SerializeField] bool testingDeleteSavedKeys;
    [SerializeField] ArchivementManager archivementManager;

    [SerializeField] float deltaTime;
    [SerializeField] float fps;

    void Awake()
    {
        archivementManager.ApplySavedItems();

        Application.targetFrameRate = (int)Screen.currentResolution.refreshRateRatio.value > 0
            ? (int)Screen.currentResolution.refreshRateRatio.value
            : 60; // Fallback auf 60 FPS

        if (testingDeleteSavedKeys)
        {
            PlayerPrefs.DeleteAll();
            Debug.Log("All PlayerPrefs have been deleted for testing.");
        }
    }

    void Update()
    {
        deltaTime += (Time.deltaTime - deltaTime) * 0.1f; // Glättung
        fps = 1 / deltaTime;
     //   Debug.Log($"FPS: {fps:F2}");
    }
}
