using System;
using System.Collections;
using System.Collections.Generic;
using TMPro;
using Unity.VisualScripting;
using UnityEngine;

public class PlayerCollision : MonoBehaviour
{
   

   public LevelManager levelManager;
   
   [SerializeField] TMP_Text levelCounter;
   public int amountLife= 3;
   [SerializeField] Transform deathParent;
   [SerializeField] SoundManager soundManager;
   [SerializeField] GameManager gameManager;
  
  
   
   
   
   

GameObject glowParent;
GameObject glowChild;

 [HideInInspector]  public GameObject targetEnter;
   
  void OnCollisionEnter(Collision collision)
    {

if(collision.gameObject.name.Equals("NextLevel")){

  levelManager.createLevelPart();
  levelCounter.text = levelManager.currentLevel.ToString();
  doGlowEffect(collision);
   soundManager.playSoundOneShot(SoundManager.SoundType.player,"checkPoint");
   GetComponent<PlayerMovement>().verticalMoves = -1;

}
if(collision.gameObject.GetComponent<Renderer>()!=null){

if(collision.gameObject.GetComponent<Renderer>().material.name.Contains("RedRain")){
amountLife--;
soundManager.playSoundOneShot(SoundManager.SoundType.player,"hissing");
if(amountLife==0){
 loose();
}
}
}




    }


  
void Update(){


    
    updateIfPlayerCanMove();
   


 

}

void doGlowEffect(Collision collision){
 glowParent = collision.gameObject.transform.Find("GlowEffectParent").gameObject;
glowParent.transform.SetParent(deathParent.transform);
 glowChild = glowParent.transform.Find("GlowEffect").gameObject;
glowChild.GetComponent<Animator>().SetTrigger("Glow");
Destroy(collision.gameObject);


}

void updateIfPlayerCanMove(){

    if(glowParent!=null && glowChild!=null){
if(glowChild.GetComponent<Animator>().GetCurrentAnimatorStateInfo(0).IsName("GlowEffectEnd")){
        GetComponent<PlayerMovement>().canMove = true;  
  
    }else{
       GetComponent<PlayerMovement>().canMove = false;
    }
   


    }
}
  

public void loose(){
  GameObject temp = transform.Find("PlayerHit_ParticleSystem").gameObject;
  soundManager.playSoundOneShot(SoundManager.SoundType.player,"explosion");
  temp.GetComponent<ParticleSystem>().Play();
  temp.transform.SetParent(deathParent);
  Camera.main.transform.SetParent(deathParent);
  gameObject.SetActive(false);
  gameManager.showDeathPanel();
  levelCounter.gameObject.SetActive(false);

if(PlayerPrefs.GetInt("HighScore")==0){
if(levelManager.currentLevel>0){
  PlayerPrefs.SetInt("HighScore",levelManager.currentLevel);

}
}else{
  if(levelManager.currentLevel>PlayerPrefs.GetInt("HighScore")){
  PlayerPrefs.SetInt("HighScore",levelManager.currentLevel);
  }
}
 


  
}

public void revivePlayer(){
GameObject temp = deathParent.Find("PlayerHit_ParticleSystem").gameObject;
  temp.transform.SetParent(gameObject.transform);
  Camera.main.transform.SetParent(gameObject.transform);
  gameObject.SetActive(true);
  GetComponent<PlayerMovement>().resetMovementCounters();  
gameManager.hideDeathPanel();
levelCounter.gameObject.SetActive(true);

}

}
