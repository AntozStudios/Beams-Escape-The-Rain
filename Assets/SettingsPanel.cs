using TMPro;
using UnityEngine;
using UnityEngine.UI;

public class SettingsPanel : MonoBehaviour
{
    [SerializeField] Toggle followPlayerToggle;
    [SerializeField] Slider followPlayerSlider;
    [SerializeField] TMP_Text followPlayerSliderValue;
    private FollowPlayer followPlayer;
    


    void Awake(){
         
        followPlayer = Camera.main.GetComponent<FollowPlayer>();
        string tempPlayerPrefToggle = PlayerPrefs.GetString("LastFollowPlayerIsOn");
        int tempPlayerSliderValue = PlayerPrefs.GetInt("LastFollowPlayerSliderValue");
        if(tempPlayerPrefToggle.Equals("True")){
            followPlayerToggle.isOn = true;
            if(tempPlayerSliderValue>0){
                followPlayerSlider.value = tempPlayerSliderValue;
followPlayer.followSpeed = tempPlayerSliderValue;
            }else{
followPlayer.followSpeed = followPlayerSlider.value;
            }
            
        }else{
                   followPlayerToggle.isOn = false;
                   followPlayerSlider.value = tempPlayerSliderValue;
        }
         followPlayerSlider.interactable = followPlayerToggle.isOn;
         followPlayer.doFollowPlayer = followPlayerToggle.isOn;
         followPlayerSliderValue.text =followPlayerSlider.value.ToString();
        
      
        followPlayerToggle.onValueChanged.AddListener((isOn)=> changedToggle()); 
        followPlayerSlider.onValueChanged.AddListener((value)=> changedSlider()
        );
        //
    }

    // Update is called once per frame
    void changedToggle(){
  followPlayerSlider.interactable = followPlayerToggle.isOn;
 followPlayer.doFollowPlayer = followPlayerToggle.isOn;
  PlayerPrefs.SetString("LastFollowPlayerIsOn",followPlayerToggle.isOn.ToString());
    }

     void changedSlider(){
  followPlayer.followSpeed = followPlayerSlider.value;
         followPlayerSliderValue.text=followPlayerSlider.value.ToString();

         PlayerPrefs.SetInt("LastFollowPlayerSliderValue",(int)followPlayerSlider.value);
    }
}
