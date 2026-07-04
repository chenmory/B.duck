import '../models/child_profile.dart';
import '../models/conversation_record.dart';
import '../models/device.dart';
import '../models/parent_user.dart';
import '../models/safety_settings.dart';
import '../models/usage_stats.dart';

final mockService = MockService();

class MockService {
  MockService();

  final ParentUser parentUser = const ParentUser(
    name: '林女士',
    phone: '138****2468',
    relation: '妈妈',
  );

  Device device = const Device(
    id: 'duck-001',
    name: '暖暖的小黄鸭',
    serialNumber: 'YD-AI-2026-0629',
    isOnline: true,
    batteryLevel: 82,
    networkName: 'Home-Kids-5G',
    firmwareVersion: 'v1.8.2',
    volume: 0.58,
    voiceName: '软萌小鸭音',
  );

  ChildProfile childProfile = const ChildProfile(
    nickname: '小满',
    age: 5,
    gender: '女',
    interests: ['恐龙', '绘本', '英语', '宇宙', '动物'],
    focusAreas: ['语言表达', '情绪陪伴', '科普启蒙'],
  );

  UsageStats usageStats = const UsageStats(
    conversationCount: 18,
    companionMinutes: 42,
    storyCount: 3,
    learningInteractions: 6,
    maxDailyMinutes: 60,
    sleepStart: '21:00',
    sleepEnd: '07:00',
    napDoNotDisturb: true,
    weeklyPlan: {
      '一': true,
      '二': true,
      '三': true,
      '四': true,
      '五': true,
      '六': true,
      '日': false,
    },
    paused: false,
  );

  SafetySettings safetySettings = const SafetySettings(
    sensitiveTopicFilter: true,
    strangerInfoAlert: true,
    negativeEmotionAlert: true,
    nightUsageAlert: true,
    blockedKeywords: ['暴力', '恐怖', '金钱', '陌生人联系方式'],
    replyStyle: '温柔陪伴',
  );

  late List<ConversationRecord> conversationRecords = _buildConversations();

  String get todaySummary =>
      '今天小满主要聊了恐龙、月亮和幼儿园午餐。她对“为什么月亮会跟着人走”很感兴趣，整体情绪积极，午睡前有一点想妈妈，小黄鸭用故事做了安抚。';

  List<ConversationRecord> _buildConversations() {
    final now = DateTime.now();
    return [
      ConversationRecord(
        id: 'c1',
        time: DateTime(now.year, now.month, now.day, 19, 42),
        childSpeech: '月亮为什么会跟着我一起走呀？',
        duckReply: '因为月亮离我们很远很远，所以你走的时候，它看起来像在温柔地陪着你。',
        emotion: '好奇',
        riskLevel: '正常',
        fullConversation:
            '孩子：月亮为什么会跟着我一起走呀？\n小黄鸭：因为月亮离我们很远很远，所以你走的时候，它看起来像在温柔地陪着你。\n孩子：那它会不会也陪小朋友睡觉？\n小黄鸭：会呀，月亮像夜晚的小灯，提醒我们慢慢安静下来，准备做一个甜甜的梦。',
        emotionAnalysis: '孩子表现出明显的探索兴趣，问题连续且具体，情绪稳定积极。',
        safetyJudgement: '内容健康，无敏感信息。可以继续鼓励孩子观察天空和自然现象。',
      ),
      ConversationRecord(
        id: 'c2',
        time: DateTime(now.year, now.month, now.day, 17, 18),
        childSpeech: '今天幼儿园的胡萝卜我没有吃完。',
        duckReply: '谢谢你告诉我。我们可以下次先吃一小口，试试看身体会不会喜欢它。',
        emotion: '低落',
        riskLevel: '正常',
        fullConversation:
            '孩子：今天幼儿园的胡萝卜我没有吃完。\n小黄鸭：谢谢你告诉我。我们可以下次先吃一小口，试试看身体会不会喜欢它。\n孩子：老师说不挑食才棒。\n小黄鸭：你愿意尝试就已经很棒了，我们慢慢来。',
        emotionAnalysis: '孩子有轻微挫败感，希望被理解。小黄鸭已用接纳式语言回应。',
        safetyJudgement: '正常生活话题，无风险。建议家长晚餐时用轻松方式延续鼓励。',
      ),
      ConversationRecord(
        id: 'c3',
        time: DateTime(now.year, now.month, now.day, 15, 6),
        childSpeech: '霸王龙会不会比房子还高？',
        duckReply: '霸王龙很高，但通常没有大房子高。它大概像两层楼那么威风。',
        emotion: '开心',
        riskLevel: '正常',
        fullConversation:
            '孩子：霸王龙会不会比房子还高？\n小黄鸭：霸王龙很高，但通常没有大房子高。它大概像两层楼那么威风。\n孩子：那它的牙齿是不是像香蕉？\n小黄鸭：有点像弯弯的大香蕉，不过可不能咬香蕉那么轻松哦。',
        emotionAnalysis: '孩子对恐龙主题持续兴奋，想象力丰富，互动节奏轻快。',
        safetyJudgement: '科普内容正常，无需关注。',
      ),
      ConversationRecord(
        id: 'c4',
        time: DateTime(now.year, now.month, now.day - 1, 20, 12),
        childSpeech: '如果有人问我家在哪里，我能告诉他吗？',
        duckReply: '这个问题很重要。家里的地址、电话和爸爸妈妈的名字，不可以告诉陌生人。',
        emotion: '害怕',
        riskLevel: '需关注',
        fullConversation:
            '孩子：如果有人问我家在哪里，我能告诉他吗？\n小黄鸭：这个问题很重要。家里的地址、电话和爸爸妈妈的名字，不可以告诉陌生人。\n孩子：那我该怎么办？\n小黄鸭：你可以去找老师、警察或者爸爸妈妈，说“我不认识这个人”。',
        emotionAnalysis: '孩子提到陌生人信息场景，带有不确定和担心情绪。',
        safetyJudgement: '涉及陌生人和家庭信息保护，建议家长了解触发原因并做一次温和的安全演练。',
        flagged: true,
      ),
    ];
  }

  ConversationRecord? findConversation(String id) {
    for (final record in conversationRecords) {
      if (record.id == id) {
        return record;
      }
    }
    return null;
  }

  void updateConversation(ConversationRecord updated) {
    conversationRecords = [
      for (final record in conversationRecords)
        if (record.id == updated.id) updated else record,
    ];
  }
}
