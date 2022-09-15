using UnityEngine;
using System.Text;
using System.Collections.Generic;

[ExecuteInEditMode]
public class ProgramSky : MonoBehaviour
{
    [Range(0,24)]
    public float Time;
    public Gradient DayColor;
    public Gradient NightColor;
    private Light sun;
    private Material programSkyMat;

    private StringBuilder stringBuilder = new StringBuilder();
    private List<Color> dayColorList = new List<Color>();
    private List<Color> nightColorList = new List<Color>();

    //每小时的角度
    private const float TIME_STEP = 15f;
    private float lastTime;

    void Start()
    {
        sun = RenderSettings.sun;
        programSkyMat = RenderSettings.skybox;

        if(sun)
        {
            float timeSeed = sun.gameObject.transform.eulerAngles.x / 24;
            Time = timeSeed;
            lastTime = Time;
        }
    }

    void Update()
    {
        // ClearBuffer
        dayColorList.Clear();
        nightColorList.Clear();
        stringBuilder.Clear();

        if (programSkyMat == null)
        {
            Debug.LogError("请设置skybox");
            return;
        }

        lastTime = Time;
        var sunEulerAngle = sun.gameObject.transform.eulerAngles;
        var timeEuler = Time * TIME_STEP - 90;
        sun.gameObject.transform.eulerAngles = new Vector3(timeEuler, 0, 0);


        if (sun != null)
        {
            stringBuilder.Clear();
            stringBuilder.Append("LToW");
            programSkyMat.SetMatrix(stringBuilder.ToString(), sun.transform.localToWorldMatrix);
        }


        for (int i = 0; i < DayColor.colorKeys.Length; i++)
        {
            stringBuilder.Clear();
            stringBuilder.Append("DayColor_");
            stringBuilder.Append(i);
            programSkyMat.SetColor(stringBuilder.ToString(), DayColor.colorKeys[i].color);
        }
        for (int i = 0; i < NightColor.colorKeys.Length; i++)
        {
            stringBuilder.Clear();
            stringBuilder.Append("NightColor_");
            stringBuilder.Append(i);
            programSkyMat.SetColor(stringBuilder.ToString(), NightColor.colorKeys[i].color);
        }
        stringBuilder.Clear();
    }
}
