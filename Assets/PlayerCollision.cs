using System;
using System.Collections;
using System.Collections.Generic;
using System.Threading.Tasks;
using TMPro;
using Unity.Services.Authentication.PlayerAccounts.Samples;
using Unity.Services.CloudSave;
using Unity.VisualScripting;
using UnityEngine;

public class PlayerCollision : MonoBehaviour
{
   

   public LevelManager levelManager;
   
   [SerializeField] TMP_Text levelCounter;
   public  TMP_Text lifeCounter; 
   public int amountLife= 3;
   [SerializeField] Transform deathParent;
   [SerializeField] SoundManager soundManager;
   [SerializeField] GameManager gameManager;
   [SerializeField] PlayerAccountsDemo playerAccountsDemo;
   
  
  

 void Start(){


  
 }

 void Awake(){
  lifeCounter.GetComponent<LifeCounter>().change(amountLife);
 }

GameObject glowParent;
GameObject glowChild;

 [HideInInspector]  public GameObject targetEnter;
   
  void OnCollisionEnter(Collision collision)
    {

if(collision.gameObject.CompareTag("NextLevel")){

  levelManager.createLevelPart();
  levelCounter.text = levelManager.currentLevel.ToString();
  doGlowEffect(collision);
   soundManager.playSoundOneShot(SoundManager.SoundType.player,"checkPoint");
  GetComponent<PlayerMovement>().zCounter =-1;

   

}
if(collision.gameObject.GetComponent<Renderer>()!=null){

if(collision.gameObject.GetComponent<Renderer>().material.name.Contains("RedRain")){
amountLife--;
soundManager.playSoundOneShot(SoundManager.SoundType.player,"hissing");
if(amountLife==0){
 loose();


}
  lifeCounter.GetComponent<LifeCounter>().change(amountLife);

}
}




    }


  
void Update(){


    
    updateIfPlayerCanMove();
       Vector3 fwd = transform.TransformDirection(Vector3.down);

    

 

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
          Destroy(glowChild);
  
    }else{
       GetComponent<PlayerMovement>().canMove = false;
    }
   


    }
    
  
}
  

public async void loose(){
  GameObject temp = transform.Find("PlayerHit_ParticleSystem").gameObject;
  soundManager.playSoundOneShot(SoundManager.SoundType.player,"explosion");
  temp.GetComponent<ParticleSystem>().Play();
  temp.transform.SetParent(deathParent);
  gameObject.SetActive(false);
  gameManager.showDeathPanel();
  levelCounter.gameObject.SetActive(false);
  amountLife =0;
  


       if(levelManager.currentLevel>PlayerPrefs.GetInt("HighScore")){
    PlayerPrefs.SetInt("HighScore",levelManager.currentLevel);
    if(PlayerPrefs.GetString("PlayMode").Equals("Cloud")){
      await playerAccountsDemo.UpdateHighScoreAsync(levelManager.currentLevel);
    }
    
  }



}

public void revivePlayerSingleplayer(){
       GetComponent<PlayerMovement>().timeToMoveCounter =0;
 
 GetComponent<PlayerMovement>().startAFKTimer = false;
GameObject temp = deathParent.Find("PlayerHit_ParticleSystem").gameObject;
  temp.transform.SetParent(gameObject.transform);
  gameObject.SetActive(true);

gameManager.hideDeathPanel();
levelCounter.gameObject.SetActive(true);
levelManager.setPlayerToStartTop();
lifeCounter.GetComponent<LifeCounter>().change(amountLife);

GetComponent<PlayerMovement>().zCounter = 0;
    GetComponent<PlayerMovement>().xCounter = 0;

    

}









}

