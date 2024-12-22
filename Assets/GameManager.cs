using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine;
using UnityEngine.SceneManagement;

public class GameManager : MonoBehaviour
{


    

public GameObject deathPanel;
[SerializeField] TMP_Text afk_Text;


[SerializeField] AudioSource[] audios;
    



public void loadScene(string name){
    SceneManager.LoadSceneAsync(name);
}



public void setMuteAudioSources(bool value){

foreach(AudioSource a in audios){
    a.mute = value;

}
}

public void hideDeathPanel(){
    setMuteAudioSources(false);
    deathPanel.SetActive(false);
}
public void showDeathPanel(){
    deathPanel.SetActive(true);
    afk_Text.gameObject.SetActive(false);
}
}
