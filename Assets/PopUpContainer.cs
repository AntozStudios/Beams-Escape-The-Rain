using UnityEngine;

public class PopUpContainer : MonoBehaviour
{
    public GameObject[] gameObjects;


    public bool anyVisible(){
        foreach(GameObject g in gameObjects){
            if(g.GetComponentInChildren<Animator>().GetNextAnimatorStateInfo(0).IsName("PopUpExit")){
                return true;
            }
        }
        return false;
    }
}
