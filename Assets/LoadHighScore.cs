using System.Collections;
using System.Collections.Generic;
using TMPro;
using UnityEngine;

public class LoadHighScore : MonoBehaviour
{
    // Start is called before the first frame update
    void Start()
    {
        GetComponent<TMP_Text>().text = "Your Record: " +PlayerPrefs.GetInt("HighScore").ToString();
    }

   
}
