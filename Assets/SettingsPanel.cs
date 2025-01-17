using TMPro;
using UnityEditor;
using UnityEngine;
using UnityEngine.PlayerLoop;
using UnityEngine.Rendering.PostProcessing;
using UnityEngine.UI;

public class SettingsPanel : MonoBehaviour
{

    [SerializeField] Slider followPlayerSlider;
    [SerializeField] TMP_Text followPlayerSliderValue;
    [SerializeField] TMP_Text postProcessSliderValue;
    
    private FollowPlayer followPlayer;


[SerializeField] TMP_Text musicValueText;
    [SerializeField] PostProcessVolume  postProcessingVolume;
    [SerializeField] Slider postProcessingSlider;
 Vignette vignette;


[SerializeField] SoundManager soundManager;
  AudioSource music;
 [SerializeField] Slider musicSlider;

    void Awake(){
        music = soundManager.sounds[2].soundChildren.GetComponent<AudioSource>();

        float tempMusicValue = PlayerPrefs.GetFloat("LastMusicVolume");
        if(tempMusicValue>0){
            music.volume = tempMusicValue;
            musicSlider.value = tempMusicValue;
        }else{
            music.volume = musicSlider.minValue;
        }
         
        followPlayer = Camera.main.GetComponent<FollowPlayer>();
        
        int tempPlayerSliderValue = PlayerPrefs.GetInt("LastFollowPlayerSliderValue");

        if(tempPlayerSliderValue>0){
            followPlayerSlider.value = tempPlayerSliderValue;
            followPlayer.doFollowPlayer = true;
            followPlayer.followSpeed = followPlayerSlider.value;
        }else{
            followPlayer.doFollowPlayer = false;
            followPlayerSlider.value = followPlayerSlider.minValue;
        }

      
       
        followPlayerSlider.onValueChanged.AddListener((value)=> changedSliderFollowPlayer());


        float tempPostProcessValue = PlayerPrefs.GetFloat("LastProcessingValue");
        
            if (postProcessingVolume.profile.TryGetSettings<Vignette>(out vignette)) {
                if(tempPostProcessValue>0){
                 vignette.intensity.value = tempPostProcessValue;
                 postProcessingSlider.value = tempPostProcessValue;
                }else{
                     vignette.intensity.value = postProcessingSlider.minValue;

                }
                
              
        
    }
        

        postProcessingSlider.onValueChanged.AddListener((value)=> changeSliderVignette());


musicSlider.onValueChanged.AddListener((value)=>changeVolume());


            postProcessSliderValue.text = PlayerPrefs.GetFloat("LastProcessingValue").ToString("F1");
           followPlayerSliderValue.text=PlayerPrefs.GetInt("LastFollowPlayerSliderValue").ToString();
  musicValueText.text=PlayerPrefs.GetFloat("LastMusicVolume").ToString("F1");
    }

    

     void changedSliderFollowPlayer(){
        if(followPlayerSlider.value>0){
            followPlayer.doFollowPlayer = true;
        }else{
            followPlayer.doFollowPlayer = false;
        }
    
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

void changeVolume(){
music.volume = musicSlider.value;
  musicValueText.text=musicSlider.value.ToString("F1");
PlayerPrefs.SetFloat("LastMusicVolume",music.volume);
}
}
