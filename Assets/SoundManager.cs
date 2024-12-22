using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SoundManager : MonoBehaviour
{
  


 [SerializeField]Sounds[] sounds;

 public enum SoundType{
player,
backgroud
}


public void Start(){


playSound(SoundType.backgroud,"rain1");


}





 public void playSound(SoundType s, string name){
    int choice = (int) s;
    sounds[choice].playChildrenAudioSource(name);
    

 }
 public void playSoundOneShot(SoundType s, string name){
    int choice = (int) s;
    sounds[choice].playChildrenAudioSourceOneShot(name);
    

 }

}

[System.Serializable]
class Sounds{




    
    [SerializeField]AudioClip[] sound;
    public GameObject soundChildren;
    


void Start(){



}



    public void playChildrenAudioSource(string soundName){
        
        soundChildren.GetComponent<AudioSource>().clip = sound[getIndex(soundName)];
        soundChildren.GetComponent<AudioSource>().Play();
        


    
}
    public void playChildrenAudioSourceOneShot(string soundName){
        
        soundChildren.GetComponent<AudioSource>().clip = sound[getIndex(soundName)];
        soundChildren.GetComponent<AudioSource>().PlayOneShot(sound[getIndex(soundName)]);
        


    
}

private int getIndex(string name){
int counter =0;
foreach(AudioClip a in sound){
    if(a.name.Equals(name)){
        return counter;
        
        }
        counter++;
}
return 0;
}



}


