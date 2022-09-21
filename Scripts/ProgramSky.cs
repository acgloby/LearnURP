using UnityEngine;
using System.Collections.Generic;

[ExecuteInEditMode]
public class ProgramSky : MonoBehaviour
{
    [Range(0,24)]
    public float m_skyTime;
    //时间流逝速度
    public float TimeSpeed = 1;
    public Vector2 CloudDirection;
    private Light sun;
    private Material programSkyMat;

    [SerializeField]
    private List<SkyColor> dayColorList = new List<SkyColor>();
    [SerializeField]
    private List<SkyColor> nightColorList = new List<SkyColor>();

    //每小时的角度
    private const float TIME_STEP = 15f;
    private const float MOON_OFFSET = 0.15f;
    private float MoonOffset = -1;

    private int curDayColorIndex;
    private int curNightColorIndex;
    private List<Color> DayColorDatas = new List<Color>();
    private List<Color> NightColorDatas = new List<Color>();

    public float SkyTime
    {
        get
        {
            return m_skyTime;
        }
        set
        {
            m_skyTime = value;
            if (m_skyTime >= 24)
            {
                m_skyTime -= 24;
            }
        }
    }

    void Start()
    {
        sun = RenderSettings.sun;
        programSkyMat = RenderSettings.skybox;

        if(sun)
        {
            float timeSeed = sun.gameObject.transform.eulerAngles.x / 24;
            SkyTime = timeSeed;
        }
    }

    void Update()
    {
        if (programSkyMat == null)
        {
            Debug.LogError("请设置skybox");
            return;
        }

        if(Application.isPlaying)
        {
            SkyTime += TimeSpeed * Time.deltaTime;
        }

        SkyColor curColor;
        SkyColor nextColor;
        if (dayColorList.Count > 1)
        {
            for (int i = 0; i < dayColorList.Count; i++)
            {
                if (SkyTime >= dayColorList[i].SkyTime)
                {
                    curDayColorIndex = i;
                }
            }

            var nextDayColorIndex = curDayColorIndex == dayColorList.Count - 1 ? 0 : curDayColorIndex + 1;
            curColor = dayColorList[curDayColorIndex];
            nextColor = dayColorList[nextDayColorIndex];
            for (int i = 0; i < 3; i++)
            {
                if (nextColor.SkyTime - SkyTime <= 1 && nextColor.SkyTime - SkyTime > 0)
                {
                    var col = Color.Lerp(nextColor.Color.colorKeys[i].color, curColor.Color.colorKeys[i].color, nextColor.SkyTime - SkyTime);
                    DayColorDatas.Add(col);
                }
                else
                {
                    DayColorDatas.Add(curColor.Color.colorKeys[i].color);
                }
            }
        }
        else if (dayColorList.Count == 1)
        {
            curColor = dayColorList[0];
            for (int i = 0; i < curColor.Color.colorKeys.Length; i++)
            {
                DayColorDatas.Add(curColor.Color.colorKeys[i].color);
            }
        }

        if (nightColorList.Count > 1)
        {
            for (int i = 0; i < nightColorList.Count; i++)
            {
                if (SkyTime >= nightColorList[i].SkyTime)
                {
                    curNightColorIndex = i;
                }
            }
            var nextNightColorIndex = curNightColorIndex == nightColorList.Count - 1 ? 0 : curNightColorIndex + 1;
            curColor = nightColorList[curNightColorIndex];
            nextColor = nightColorList[nextNightColorIndex];
            for (int i = 0; i < 3; i++)
            {
                if (nextColor.SkyTime - SkyTime <= 1 && nextColor.SkyTime - SkyTime > 0)
                {
                    var col = Color.Lerp(nextColor.Color.colorKeys[i].color, curColor.Color.colorKeys[i].color, nextColor.SkyTime - SkyTime);
                    NightColorDatas.Add(col);
                }
                else
                {
                    NightColorDatas.Add(curColor.Color.colorKeys[i].color);
                }
            }

        }
        else if(nightColorList.Count == 1)
        {
            curColor = nightColorList[0];
            for (int i = 0; i < curColor.Color.colorKeys.Length; i++)
            {
                NightColorDatas.Add(curColor.Color.colorKeys[i].color);
            }
        }
      

        if (sun != null)
        {
            var timeEuler = SkyTime * TIME_STEP - 90;
            sun.gameObject.transform.eulerAngles = new Vector3(timeEuler, 0, 0);
            programSkyMat.SetMatrix("LToW", sun.transform.localToWorldMatrix);
        }

        for (int i = 0; i < DayColorDatas.Count; i++)
        {
            var name = string.Format("DayColor_{0}", i);
            programSkyMat.SetColor(name, DayColorDatas[i]);
        }
        for (int i = 0; i < NightColorDatas.Count; i++)
        {
            var name = string.Format("NightColor_{0}", i);
            programSkyMat.SetColor(name, NightColorDatas[i]);
        }

        programSkyMat.SetVector("CloudDirection", CloudDirection);
        programSkyMat.SetFloat("TimeSpeed", TimeSpeed);
        //programSkyMat.SetFloat("_MoonMask", MoonOffset);

        DayColorDatas.Clear();
        NightColorDatas.Clear();
    }
}

[System.Serializable]
public struct SkyColor
{
    public float SkyTime;
    public Gradient Color;
}
