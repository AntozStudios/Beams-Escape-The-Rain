using TMPro;
using UnityEditor;
using UnityEngine;
using UnityEngine.PlayerLoop;
using UnityEngine.Rendering.PostProcessing;
using UnityEngine.UI;

public class SettingsPanel : MonoBehaviour
{
    [SerializeField] Toggle followPlayerToggle;
    [SerializeField] Slider followPlayerSlider;
    [SerializeField] TMP_Text followPlayerSliderValue;
    [SerializeField] TMP_Text postProcessSliderValue;
    private FollowPlayer followPlayer;


    [SerializeField] PostProcessVolume  postProcessingVolume;
    [SerializeField] Slider postProcessingSlider;
 Vignette vignette;

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
        
      
        followPlayerToggle.onValueChanged.AddListener((isOn)=> changedTogglePlayer()); 
        followPlayerSlider.onValueChanged.AddListener((value)=> changedSliderFollowPlayer());


        float tempPostProcessValue = PlayerPrefs.GetFloat("LastProcessingValue");
        if(tempPostProcessValue>0){
            if (postProcessingVolume.profile.TryGetSettings<Vignette>(out vignette)) {
                 vignette.intensity.value = tempPostProcessValue;
                 postProcessingSlider.value = tempPostProcessValue;
                 postProcessSliderValue.text = vignette.intensity.value.ToString("F1");
        
    }
        }

        postProcessingSlider.onValueChanged.AddListener((value)=> changeSliderVignette());
    }

    // Update is called once per frame
    void changedTogglePlayer(){
  followPlayerSlider.interactable = followPlayerToggle.isOn;
 followPlayer.doFollowPlayer = followPlayerToggle.isOn;
  PlayerPrefs.SetString("LastFollowPlayerIsOn",followPlayerToggle.isOn.ToString());
    }

     void changedSliderFollowPlayer(){
  followPlayer.followSpeed = followPlayerSlider.value;
         followPlayerSliderValue.text=followPlayerSlider.value.ToString();

         PlayerPrefs.SetInt("LastFollowPlayerSliderValue",(int)followPlayerSlider.value);
    }

void changeSliderVignette() {
  

    if (postProcessingVolume.profile.TryGetSettings<Vignette>(out vignette)) {
        vignette.intensity.value = postProcessingSlider.value;
        PlayerPrefs.SetFloat("LastProcessingValue",vignette.intensity.value);
        postProcessSliderValue.text = vignette.intensity.value.ToString("F1");
    }
}

}
