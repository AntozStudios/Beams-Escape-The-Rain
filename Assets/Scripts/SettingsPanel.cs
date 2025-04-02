using TMPro;
using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.Rendering.PostProcessing;
using UnityEngine.UI;

public class SettingsPanel : MonoBehaviour
{

    [SerializeField] Slider followPlayerSlider;
    [SerializeField] TMP_Text followPlayerSliderValue;
    [SerializeField] TMP_Text postProcessSliderValue;

    private FollowPlayer followPlayer;


    [SerializeField] TMP_Text musicValueText;
    [SerializeField] PostProcessVolume postProcessingVolume;
    [SerializeField] Slider postProcessingSlider;
    Vignette vignette;


    [SerializeField] SoundManager soundManager;
    AudioSource music,rain;
    [SerializeField] Slider musicSlider;


    [SerializeField] TMP_Text rainValueText;
    [SerializeField] Slider rainSlider;

    void Awake()
    {
        rain = soundManager.sounds[1].soundChildren.GetComponent<AudioSource>();
        music = soundManager.sounds[2].soundChildren.GetComponent<AudioSource>();





    }

//RainVolumeChanged
//LastRainVolume
    void Start()
    {
        ///////////////////
        
         string tutorialFinished = PlayerPrefs.GetString("TutorialPlayed");

   



////////////////////////////////////////////////////////////////////////
float tempRainVolume = PlayerPrefs.GetFloat("LastRainVolume");
int tempVolumeRain_Changed = PlayerPrefs.GetInt("VolumeRain_Changed");
if(tempVolumeRain_Changed==0){
rain.volume = rainSlider.value; // Default value by Slider
}else{
    rain.volume = tempRainVolume; // Saved value
    rainSlider.value = tempRainVolume;
}

rainValueText.text = rainSlider.value.ToString("F2");
/////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////
float tempMusicVolume = PlayerPrefs.GetFloat("LastMusicVolume");
int tempVolumeMusic_Changed = PlayerPrefs.GetInt("VolumeMusic_Changed");
if(tempVolumeMusic_Changed==0){
music.volume = musicSlider.value; // Default value by Slider
}else{
    music.volume = tempMusicVolume; // Saved value
    musicSlider.value = tempMusicVolume;
}

musicValueText.text = musicSlider.value.ToString("F2");
/////////////////////////////////////////////////////////////////////
         




        followPlayer = Camera.main.GetComponent<FollowPlayer>();

        int tempPlayerSliderValue = PlayerPrefs.GetInt("LastFollowPlayerSliderValue");

        if (tempPlayerSliderValue > 0)
        {
            followPlayerSlider.value = tempPlayerSliderValue;
            followPlayer.doFollowPlayer = true;
            followPlayer.followSpeed = followPlayerSlider.value;
            followPlayerSliderValue.text = PlayerPrefs.GetInt("LastFollowPlayerSliderValue").ToString("F1");
        }
        else
        {
            followPlayer.doFollowPlayer = true;
            followPlayer.followSpeed = followPlayerSlider.value;
            followPlayerSliderValue.text = followPlayerSlider.value.ToString("F1");
        }



        followPlayerSlider.onValueChanged.AddListener((value) => changedSliderFollowPlayer());

        int tempValueVignette_Changed = PlayerPrefs.GetInt("ValueVignette_Changed");

        

        float tempPostProcessValue = PlayerPrefs.GetFloat("LastProcessingValue");

        if (postProcessingVolume.profile.TryGetSettings<Vignette>(out vignette))
        {
       if(tempValueVignette_Changed==0){
    vignette.intensity.value = postProcessingSlider.value;
      postProcessSliderValue.text = PlayerPrefs.GetFloat("LastProcessingValue").ToString("F1");
        }else{
            float tempLastVolume = PlayerPrefs.GetFloat("LastProcessingValue");
            vignette.intensity.value = tempLastVolume;
          

        }
  postProcessingSlider.value = vignette.intensity.value;      
  postProcessSliderValue.text = vignette.intensity.value.ToString("F1");


        }


        postProcessingSlider.onValueChanged.AddListener((value) => changeSliderVignette());


        musicSlider.onValueChanged.AddListener((value) => changeVolume_Music());
                rainSlider.onValueChanged.AddListener((value) => changeVolume_Rain());


    }



    void changedSliderFollowPlayer()
    {
        if (followPlayerSlider.value > 0)
        {
            followPlayer.doFollowPlayer = true;
        }
        else
        {
            followPlayer.doFollowPlayer = false;
        }

        followPlayer.followSpeed = followPlayerSlider.value;
        followPlayerSliderValue.text = followPlayerSlider.value.ToString();

        PlayerPrefs.SetInt("LastFollowPlayerSliderValue", (int)followPlayerSlider.value);
    }

    void changeSliderVignette()
    {


        if (postProcessingVolume.profile.TryGetSettings<Vignette>(out vignette))
        {
            vignette.intensity.value = postProcessingSlider.value;
            PlayerPrefs.SetFloat("LastProcessingValue", vignette.intensity.value);
            postProcessSliderValue.text = vignette.intensity.value.ToString("F1");
            PlayerPrefs.SetInt("ValueVignette_Changed",1);
        }
    }

    void changeVolume_Music()
    {
        music.volume = musicSlider.value;
        musicValueText.text = musicSlider.value.ToString("F2");
        PlayerPrefs.SetFloat("LastMusicVolume", musicSlider.value);
        PlayerPrefs.SetInt("VolumeMusic_Changed",1);
       
    }
     void changeVolume_Rain()
    {
        rain.volume = rainSlider.value;
        rainValueText.text = rainSlider.value.ToString("F2");
        PlayerPrefs.SetFloat("LastRainVolume", rainSlider.value);
        PlayerPrefs.SetInt("VolumeRain_Changed",1);

    }
}
