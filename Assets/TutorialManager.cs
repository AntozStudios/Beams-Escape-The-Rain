using System.Collections;
using TMPro;
using Unity.VisualScripting;
using UnityEngine;
using UnityEngine.SceneManagement;

public class TutorialManager : MonoBehaviour
{
    

    [SerializeField] GameObject player;

    [SerializeField] LevelManager levelManager;


[SerializeField] GameObject yesNoPrefab;
[SerializeField] GameObject nextPrefab;

[SerializeField] GameObject swipeObject;
[SerializeField] TMP_Text swipeText;

[SerializeField] GameObject soundManager;

    
    int tutorialState = 0;
AudioSource rain;
    private bool checkSwipe;

    void Awake(){
                rain = soundManager.GetComponent<SoundManager>().sounds[1].soundChildren.GetComponent<AudioSource>();

   string tutorialFinished = PlayerPrefs.GetString("TutorialPlayed");

if(tutorialFinished.Equals("Yes")){
    this.enabled = false;
   
}
    }

    void Start(){

        rain.mute = true;
        checkSwipe = true;
        player.GetComponent<PlayerMovement>().canDownSwipe = false;
          player.GetComponent<PlayerMovement>().canLeftSwipe = false;
            player.GetComponent<PlayerMovement>().canRightSwipe = false;
              player.GetComponent<PlayerMovement>().canUpSwipe = false;

        player.GetComponent<PlayerMovement>().canMove = false;
        player.GetComponent<PlayerMovement>().playerHasToMove = false;
        levelManager.gameStarted = true;
    }


    public void Update(){

if(this!=null){

            if(tutorialState==0){


                   levelManager.setRainForLevel(0,false); 
                   levelManager.getCurrentNextLevel().SetActive(false);
                   
            GameObject playTutorial = Instantiate(yesNoPrefab,transform);
            playTutorial.GetComponent<PopUp>().content.text ="Do you want to play the Tutorial?"; 
            playTutorial.GetComponent<PopUp>().showPopUp();
            playTutorial.GetComponent<PopUp>().yesButton.onClick.AddListener(()=>{
                 swipeObject.SetActive(true);
    swipeText.gameObject.SetActive(true);
                tutorialState = 1;
               
                playTutorial.GetComponent<PopUp>().hidePopUp();
            });

            playTutorial.GetComponent<PopUp>().noButton.onClick.AddListener(()=>{

                tutorialState = 13;
            PlayerPrefs.SetString("TutorialPlayed","Yes");
            StartCoroutine(LoadSceneWithDelay());
            
                
        
            });
        
   
            }else if(tutorialState==1){
                GameObject swipeTutorial = Instantiate(nextPrefab,transform);
              
                swipeTutorial.GetComponent<PopUp>().content.text ="Let's learn the controls.";
                swipeTutorial.GetComponent<PopUp>().nextButton.onClick.AddListener(()=> {
                    tutorialState=2;
                    swipeTutorial.GetComponent<PopUp>().hidePopUp();
                });
                swipeTutorial.GetComponent<PopUp>().showPopUp();
                

            }else if(tutorialState==2){
                player.GetComponent<PlayerMovement>().canMove = true;
                player.GetComponent<PlayerMovement>().canLeftSwipe = true;
                swipeObject.GetComponent<Animator>().SetBool("Left",true);
                swipeText.text ="SWIPE LEFT";
                
                
            }else if(tutorialState==3){
                swipeObject.GetComponent<Animator>().SetBool("Left",false);
                swipeObject.GetComponent<Animator>().SetBool("Right",true);
               
                player.GetComponent<PlayerMovement>().canLeftSwipe = false;
                player.GetComponent<PlayerMovement>().canRightSwipe = true;
                swipeText.text ="SWIPE RIGHT"; 
            }else if(tutorialState==4){
                swipeText.text ="SWIPE UP"; 
                swipeObject.GetComponent<Animator>().SetBool("Right",false);
                swipeObject.GetComponent<Animator>().SetBool("Up",true);
                player.GetComponent<PlayerMovement>().canRightSwipe = false;
                player.GetComponent<PlayerMovement>().canUpSwipe = true;
            }else if(tutorialState==5){
                swipeText.text ="SWIPE DOWN"; 
                swipeObject.GetComponent<Animator>().SetBool("Up",false);
                swipeObject.GetComponent<Animator>().SetBool("Down",true);
                player.GetComponent<PlayerMovement>().canUpSwipe = false;
                player.GetComponent<PlayerMovement>().canDownSwipe = true;

            }else if (tutorialState==6){
                swipeObject.GetComponent<Animator>().SetBool("Down",false);
                player.GetComponent<PlayerMovement>().canDownSwipe = false;
                swipeText.text ="";
                swipeObject.SetActive(false);
                GameObject levelGrass = Instantiate(nextPrefab,transform);
                levelGrass.GetComponent<PopUp>().content.text ="You have to keep moving, you can't stay still for long.       Grass: Max 6 seconds before you die.";
                levelGrass.GetComponent<PopUp>().showPopUp();
                levelGrass.GetComponent<PopUp>().nextButton.onClick.AddListener(()=> {
                    
                    levelGrass.GetComponent<PopUp>().hidePopUp(); 
                   
                    
                    tutorialState = 7;});
                
            }else if(tutorialState==7){
                GameObject levelIce = Instantiate(nextPrefab,transform);
                  levelManager.createField.drawField(levelManager.iceMaterial);
                levelIce.GetComponent<PopUp>().content.text ="Ice: Max 4 seconds before you die.";
                levelIce.GetComponent<PopUp>().showPopUp();
                levelIce.GetComponent<PopUp>().nextButton.onClick.AddListener(()=> {
                    
                    levelIce.GetComponent<PopUp>().hidePopUp(); 
                    
                  
                    tutorialState =8;});
                
            }
            else if(tutorialState==8){
                GameObject levelSand = Instantiate(nextPrefab,transform);
                levelManager.createField.drawField(levelManager.sandMaterial);
                levelSand.GetComponent<PopUp>().content.text ="Sand: Max 2 seconds before you die.";
                 
                levelSand.GetComponent<PopUp>().showPopUp();
                levelSand.GetComponent<PopUp>().nextButton.onClick.AddListener(()=> {
                    
                    
                    levelSand.GetComponent<PopUp>().hidePopUp();
                    levelManager.createField.drawField(levelManager.grassMaterial);
                    levelManager.setRainForLevel(0,true); 
                    rain.mute = false;
                    tutorialState =9;
                    });
                
            }else if(tutorialState==9){
                GameObject rainTutorial = Instantiate(nextPrefab,transform);
                rainTutorial.GetComponent<PopUp>().content.text="Each level has a unique rain pattern.    The pattern stays the same after respawning, but be careful – you must dodge the red rain!";
                rainTutorial.GetComponent<PopUp>().showPopUp();
                rainTutorial.GetComponent<PopUp>().nextButton.onClick.AddListener(()=> {
                    

                    rainTutorial.GetComponent<PopUp>().hidePopUp();
                       levelManager.getCurrentNextLevel().SetActive(true);
                    tutorialState =10; 
                    
                    });
            }else if(tutorialState==10){
                   GameObject frameTutorial = Instantiate(nextPrefab,transform);
                frameTutorial.GetComponent<PopUp>().content.text="Reach the frame in each level.";
                frameTutorial.GetComponent<PopUp>().showPopUp();
                frameTutorial.GetComponent<PopUp>().nextButton.onClick.AddListener(()=> {
            
                 frameTutorial.GetComponent<PopUp>().hidePopUp();
                 
                  tutorialState =11;});
            }else if(tutorialState==11){
                GameObject finalTutorial = Instantiate(nextPrefab,transform);
                finalTutorial.GetComponent<PopUp>().content.text="Try to reach the frame – you'll get god mode for practice.";
                finalTutorial.GetComponent<PopUp>().showPopUp();
                finalTutorial.GetComponent<PopUp>().nextButton.onClick.AddListener(()=> {
                    checkSwipe = false;
                    player.GetComponent<PlayerCollision>().godMode = true;
                    player.GetComponent<PlayerMovement>().canUpSwipe = true;
                    player.GetComponent<PlayerMovement>().canDownSwipe = true;
                    player.GetComponent<PlayerMovement>().canLeftSwipe = true;
                    player.GetComponent<PlayerMovement>().canRightSwipe = true;
                     finalTutorial.GetComponent<PopUp>().hidePopUp();
                               
                   

                    
                   
                });

            }else if(tutorialState ==12){
                GameObject closeTutorial = Instantiate(nextPrefab,transform);
                closeTutorial.GetComponent<PopUp>().content.text = "Close tutorial.";
                closeTutorial.GetComponent<PopUp>().showPopUp();
                closeTutorial.GetComponent<PopUp>().nextButton.onClick.AddListener(()=>{
               
                 PlayerPrefs.SetString("TutorialPlayed","Yes");
                StartCoroutine(LoadSceneWithDelay());


                });
             tutorialState =13;
            }else if(tutorialState==13){

            }


         if(tutorialState <13 && levelManager.currentLevel==1){
                tutorialState = 12;
         }else if (tutorialState <13 && levelManager.currentLevel==0){
tutorialState = -1;
      
         }
   



if(checkSwipe){
    if(player!=null){
if(player.GetComponent<PlayerMovement>().xCounter==-1 && player.GetComponent<PlayerMovement>().lastSwipe == PlayerMovement.LastSwipe.LEFT){
    tutorialState = 3;
}

if(player.GetComponent<PlayerMovement>().xCounter==0 && player.GetComponent<PlayerMovement>().lastSwipe == PlayerMovement.LastSwipe.RIGHT){
   tutorialState = 4;
}
if(player.GetComponent<PlayerMovement>().zCounter==1 && player.GetComponent<PlayerMovement>().lastSwipe == PlayerMovement.LastSwipe.UP){
    tutorialState = 5;
}
if(player.GetComponent<PlayerMovement>().zCounter==0 && player.GetComponent<PlayerMovement>().lastSwipe == PlayerMovement.LastSwipe.DOWN){
    tutorialState = 6;
    player.GetComponent<PlayerMovement>().lastSwipe = PlayerMovement.LastSwipe.IDLE;
}

    }

}




Debug.Log(tutorialState);

    }




    }

   
IEnumerator LoadSceneWithDelay()
{
    yield return new WaitForSeconds(1f);  // Kleine Verzögerung für sicheres Speichern
      SceneManager.LoadSceneAsync(SceneManager.GetActiveScene().name);
}


}
