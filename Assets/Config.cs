using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Config : MonoBehaviour
{
    // Start is called before the first frame update
   void Awake(){
    Application.targetFrameRate = (int)Screen.currentResolution.refreshRateRatio.value;
   }
    // Update is called once per frame
    void Update()
    {
      
    }
}
