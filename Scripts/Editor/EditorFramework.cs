using UnityEngine;
using UnityEditor;


public class EditorFramework<T> : EditorWindow where T : EditorFramework<T>
{
    /// <summary>
    /// 刷新间隔时间
    /// </summary>
    private const float REPAINT_INTERVAL = 0.1f;
    private bool playing;
    private float repaintInterval;
    protected static T window;

    public EditorFramework()
    {

    }

    public bool IsPlaying
    {
        get
        {
            return playing;
        }
    }

    /// <summary>
    /// 打开编辑器入口
    /// </summary>
    public static void OpenEditor()
    {
        window = GetWindow<T>(false, typeof(T).Name, true);
        if (window == null)
            return;
        window.Show();
    }

    /// <summary>
    /// 关闭编辑器入口
    /// </summary>
    public static void CloseEditor()
    {
        if (window == null)
            return;
        window.Close();
    }

    /// <summary>
    /// 刷新编辑器入口
    /// </summary>
    public static void Refresh()
    {
        if (window == null)
            return;
        window.OnRefresh();
        window.Repaint();
    }

    /// <summary>
    /// 打开编辑器时执行
    /// </summary>
    public virtual void OnStartPlay()
    {

    }

    /// <summary>
    /// 关闭编辑器时执行
    /// </summary>
    public virtual void OnStopPlay()
    {

    }

    /// <summary>
    /// 调用Refresh()编辑器刷新时执行
    /// </summary>
    public virtual void OnRefresh()
    {

    }

    /// <summary>
    /// 在Update中调用
    /// </summary>
    protected virtual void OnUpdate()
    {

    }

    protected virtual void Awake()
    {

    }

    protected virtual void OnEnable()
    {

    }

    protected virtual void OnDisable()
    {

    }

    protected virtual void OnDestroy()
    {

    }

    protected virtual void OnGUI()
    {

    }

    private void Update()
    {
        if (Application.isPlaying)
        {
            if (!playing)
            {
                playing = true;
                StartPlay();
            }
        }
        else
        {
            if (playing)
            {
                playing = false;
                StopPlay();
            }
        }

        OnUpdate();
        repaintInterval += Time.deltaTime;
        if (repaintInterval >= REPAINT_INTERVAL)
        {
            repaintInterval = 0;
            Repaint();
        }
    }

    private void StartPlay()
    {
        OnStartPlay();
    }

    private void StopPlay()
    {
        OnStopPlay();
    }
}
