
using UnityEngine;

public class Config : MonoBehaviour
{
    [SerializeField] GameObject player;
    [SerializeField] bool testingDeleteSavedKeys;
    [SerializeField] ArchivementManager archivementManager;
    
    
    // Start is called before the first frame update
   void Awake(){
  
archivementManager.ApplySavedItems();
 
   
   
    Application.targetFrameRate = (int)Screen.currentResolution.refreshRateRatio.value;
    if(testingDeleteSavedKeys){
        PlayerPrefs.DeleteAll();

    }
   }
   void Start(){

   }
    // Update is called once per frame
    void Update()
    {
      
    }
}
