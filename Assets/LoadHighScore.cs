using System.Collections;
using System.Collections.Generic;
using System.Threading.Tasks;
using TMPro;
using UnityEngine;

public class LoadHighScore : MonoBehaviour
{
    [SerializeField] TMP_Text text;

    void Start(){
    
    text.text =PlayerPrefs.GetInt("HighScore").ToString();
    }
   
}
