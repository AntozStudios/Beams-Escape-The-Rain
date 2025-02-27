using UnityEngine;

public class Config : MonoBehaviour
{

    [SerializeField] bool testingDeleteSavedKeys;
    [SerializeField] ArchivementManager archivementManager;

   
    void Awake()
    {
        archivementManager.ApplySavedItems();

        Application.targetFrameRate = (int)Screen.currentResolution.refreshRateRatio.value ;
      

        if (testingDeleteSavedKeys)
        {
            PlayerPrefs.DeleteAll();
            Debug.Log("All PlayerPrefs have been deleted for testing.");
        }
    }

   
}
