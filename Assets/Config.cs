using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Config : MonoBehaviour
{
    [SerializeField] GameObject player;
    
    // Start is called before the first frame update
   void Awake(){
    ArchivementManager.ApplySavedItems(player,player.GetComponent<PlayerChildren>().playerCamera);
    Application.targetFrameRate = (int)Screen.currentResolution.refreshRateRatio.value;
   }
    // Update is called once per frame
    void Update()
    {
      
    }
}
