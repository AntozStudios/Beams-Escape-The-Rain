using System.Collections;
using UnityEngine;
using TMPro;

public class PlayerMovement : MonoBehaviour
{
    private Vector2 firstTouch, lastTouch; // Touch-Positionen
    private float movementSize;
    public bool canMove;

    public int verticalMoves;

    public int horizontalMoves;

    public GameObject[] hideObjectWhenGameStarts;

    
[SerializeField] TMP_Text levelCounter;    

    [SerializeField] SoundManager soundManager;

    [SerializeField] LevelManager levelManager;

  //  bool gameStarted;



[HideInInspector]public float timeToMoveCounter;
public float timeToMoveMax;


[HideInInspector]public float startAfkCounter;
[HideInInspector]public float startAfkMax;

public bool playerHasToMove;


public bool startAFKTimer;


void Awake(){
    startAfkCounter = startAfkMax;
   
}
    void Start()
    {
        movementSize = transform.localScale.x;
    }

    void Update()
    {

        hideGameObjects(!levelManager.gameStarted);
        levelCounter.gameObject.SetActive(levelManager.gameStarted);
    

       
if(canMove ){
     
  

       HandleKeyboard();
       HandleTouchInput();
        
  
        

  

        }

   


         

  
        
        
updatePlayerHasToMove();





      
    }

    void HandleKeyboard()
    {
        if (Input.GetKeyUp(KeyCode.LeftArrow))
        {
            if (horizontalMoves > -3)
            {
                MovePlayer(Vector3.left);
                  timeToMoveCounter =0;
                horizontalMoves--;
            }
        }
        else if (Input.GetKeyUp(KeyCode.RightArrow))
        {
            if (horizontalMoves <= 2)
            {
                MovePlayer(Vector3.right);
               timeToMoveCounter =0;
                horizontalMoves++;
            }
        }
        else if (Input.GetKeyUp(KeyCode.UpArrow))
        {
            if (verticalMoves <= 6)
            {
                MovePlayer(Vector3.forward);
                 timeToMoveCounter =0;
                verticalMoves += 1;
            }
        }
        else if (Input.GetKeyUp(KeyCode.DownArrow))
        {
            if (verticalMoves > 0)
            {
                MovePlayer(Vector3.back);
                   timeToMoveCounter =0;
                verticalMoves -= 1;
            }
        }
        

    }

    void HandleTouchInput()
{
    // Eingaben nur zulassen, wenn das Spiel gestartet ist
    if ( Input.touchCount > 0)
    {
        Touch touch = Input.GetTouch(0);
        

        // Beim Beginn des Wischens, Position speichern
        if (touch.phase == TouchPhase.Began)
        {
            firstTouch = touch.position;
        }
        // Beim Ende des Wischens, Position prüfen und entscheiden, in welche Richtung der Spieler bewegt wird
        else if (touch.phase == TouchPhase.Ended)
        {
            lastTouch = touch.position;
            
            HandleSwipe(firstTouch, lastTouch);
            
            
        }
    }
}
    void HandleSwipe(Vector2 startTouch, Vector2 endTouch)
    {
        float swipeThreshold = 100f; // Mindest-Swipe-Länge für eine Bewegung

        Vector2 swipeDirection = endTouch - startTouch;
        if (swipeDirection.magnitude >= swipeThreshold)
        {
            // Horizontaler Swipe
            if (Mathf.Abs(swipeDirection.x) > Mathf.Abs(swipeDirection.y))
            {
                if (swipeDirection.x > 0) // Swipe nach rechts
                {
                    if (horizontalMoves <= 2)
                    {
                        MovePlayer(Vector3.right);
                         timeToMoveCounter =0;
                        horizontalMoves++;
                    }
                }
                else // Swipe nach links
                {
                    if (horizontalMoves > -3)
                    {
                        MovePlayer(Vector3.left);
                          timeToMoveCounter =0;
                        horizontalMoves--;
                    }
                }
            }
            // Vertikaler Swipe
            else
            {
                if (swipeDirection.y > 0) // Swipe nach oben
                {
                    if (verticalMoves <= 6)
                    {
                        MovePlayer(Vector3.forward);
                      timeToMoveCounter =0;
                        verticalMoves++;
                    }
                }
                else // Swipe nach unten
                {
                    if (verticalMoves > 0)
                    {
                        MovePlayer(Vector3.back);
                   timeToMoveCounter =0;
                        verticalMoves--;
                    }
                }
            }
        }
    }

    void MovePlayer(Vector3 direction)
    {
        if(canMove){
 transform.position += direction * movementSize;
        soundManager.playSoundOneShot(SoundManager.SoundType.player, "player");
        levelManager.gameStarted = true;
        }
       
    }

    


public void timeToMoveCountdown(){
    if(timeToMoveCounter>timeToMoveMax){
    startAFKTimer = true;
    }else{
        startAFKTimer = false;
    }
    timeToMoveCounter+=Time.deltaTime;
    
}

public void afkCountdown(){
    if(startAFKTimer){
    if(startAfkCounter<=0){
        GetComponent<PlayerCollision>().loose();
    }
     startAfkCounter-=Time.deltaTime;
}else{
    startAfkCounter = startAfkMax;
}
}

void updatePlayerHasToMove(){
    if(playerHasToMove){
if(verticalMoves>=1){

timeToMoveCountdown();
afkCountdown();
}

}

}

public void resetMovementCounters(){
    verticalMoves =0;
    horizontalMoves =0;

}

private void hideGameObjects( bool value){
    foreach(GameObject g in hideObjectWhenGameStarts){
        g.SetActive(value);
    }
}
public void startGame(){
    levelManager.gameStarted = true;
    canMove = true;

}


    }
