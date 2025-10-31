require 'telegram/bot'

token = '8443547437:AAFVQDyVM8zLQYxfPIo7A4YX7y8T0BDJbR4'

# Хэш для хранения прогресса пользователей
user_progress = {}

# Шаги приготовления зелья
BREWING_STEPS = [
  {
    instruction: "1. Налей в сотейник 100 мл молока, добавь 5-6 ирисок, 1/2 ложку корицы и 1/2 ложку имбиря",
    gif: "step1.gif"
  },
  {
    instruction: "2. Растопи ириски до небольшого загустения общей массы",
    gif: "step2.gif"
  },
  {
    instruction: "3. Добавь пломбир (он в морозилке), но не забудь освободь из вафельного стаканчика. Растопи всё до однородной массы",
    gif: "step3.gif"
  },
  {
    instruction: "4. Налей готовую массу в стакан",
    gif: "step4.gif"
  },
  {
    instruction: "5. Достань из холодильника бутылочку лимонада в стекле. Заполни почти до самого верха",
    gif: "step5.gif"
  },
  {
    instruction: "6. Слегка размешай",
    gif: "step6.gif"
  },
  {
    instruction: "7. Достань из холодильника взбитые сливки и укрась большой белой шапкой этот прекрасный напиток",
    gif: "step7.gif"
  },
  {
    instruction: "8. Возьми трубочку и пробуй!",
    gif: "step8.gif"
  }
]

# Метод для безопасной отправки с обработкой ошибок
def safe_send(bot, chat_id, &block)
  retries = 0
  begin
    block.call
  rescue Telegram::Bot::Exceptions::ResponseError => e
    if e.error_code == 429
      retry_after = e.response['parameters']['retry_after'] || 30
      puts "Превышен лимит запросов. Ждем #{retry_after} секунд..."
      sleep(retry_after)
      retries += 1
      retry if retries <= 3
    else
      raise e
    end
  end
end

# Определяем методы перед основным кодом
def send_brewing_step(bot, chat_id, step_index)
  step = BREWING_STEPS[step_index]
  
  # Отправляем гифку шага с обработкой ошибок
  safe_send(bot, chat_id) do
    bot.api.send_animation(
      chat_id: chat_id,
      animation: Faraday::UploadIO.new(step[:gif], 'image/gif')
    )
  end
  
  sleep(3) # Увеличиваем задержку
  
  # Отправляем инструкцию с кнопкой
  buttons = [[Telegram::Bot::Types::InlineKeyboardButton.new(
    text: 'Готово!',
    callback_data: "step_#{step_index}"
  )]]
  
  markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: buttons)
  
  safe_send(bot, chat_id) do
    bot.api.send_message(
      chat_id: chat_id,
      text: step[:instruction],
      reply_markup: markup
    )
  end
end

def handle_step_completion(bot, message, user_progress)
  data_parts = message.data.split('_')
  step_index = data_parts[1].to_i
  
  user_id = message.from.id
  
  # Подтверждаем нажатие кнопки
  safe_send(bot, user_id) do
    bot.api.answer_callback_query(callback_query_id: message.id, text: "Принято! ✅")
  end
  
  if step_index + 1 < BREWING_STEPS.size
    # Следующий шаг
    user_progress[user_id] ||= {}
    user_progress[user_id][:current_step] = step_index + 1
    
    sleep(2) # Увеличиваем задержку
    
    # Комментарий Снейпа между шагами
    snape_comments = [
      "Северус - Продолжайте... и постарайтесь не взорвать котел на этот раз.",
      "Северус - Медленно... очень медленно...",
      "Северус - Вы удивительно некоординированы для волшебницы.",
      "Северус - Даже первокурсник справился бы лучше.",
      "Северус - Потрачено уже 10 минут... сколько можно?"
    ]
    
    safe_send(bot, user_id) do
      bot.api.send_message(
        chat_id: user_id,
        text: snape_comments.sample
      )
    end
    
    sleep(3) # Увеличиваем задержку
    
    send_brewing_step(bot, user_id, step_index + 1)
  else
    # Все шаги завершены - шутка от "друга"
    safe_send(bot, user_id) do
      bot.api.send_message(
        chat_id: user_id,
        text: "P.S. как ты уже поняла, это не Дамблдор, а твой хороший друг, хихихихи"
      )
    end
    
    sleep(4) # Увеличиваем задержку
    
    # Реакция Снейпа
    safe_send(bot, user_id) do
      bot.api.send_animation(
        chat_id: user_id,
        animation: Faraday::UploadIO.new('snape_reaction.gif', 'image/gif')
      )
    end
    
    sleep(3) # Увеличиваем задержку
    
    safe_send(bot, user_id) do
      bot.api.send_message(
        chat_id: user_id,
        text: "Мда, вы даже не смогли справиться с этим заданием и приготовили... Что это? Сливочное пиво!? Хм... это мой любимый напиток."
      )
    end
    
    sleep(3) # Увеличиваем задержку
    
    safe_send(bot, user_id) do
      bot.api.send_message(
        chat_id: user_id,
        text: "Так уж и быть, ставлю вам зачет мисс Токарева, но лишь в этот раз! А теперь уходите, вас ждут в следующей комнате: t.me/dumbledore_dr_bot",
        parse_mode: 'Markdown'
      )
    end
    
    # Очищаем прогресс
    user_progress.delete(user_id)
  end
end

# Основной код бота
Telegram::Bot::Client.run(token) do |bot|
  bot.listen do |message|
    case message
    when Telegram::Bot::Types::Message
      case message.text
      when '/start'
        # Суровое приветствие от Снейпа
        safe_send(bot, message.chat.id) do
          bot.api.send_animation(
            chat_id: message.chat.id,
            animation: Faraday::UploadIO.new('snape_hello.gif', 'image/gif')
          )
        end

        safe_send(bot, message.chat.id) do
          bot.api.send_message(
            chat_id: message.chat.id,
            text: "Мисс Токарева, вы заставляете меня ждать. Вам кажется это забавным? Сейчас посмотрим что тут забавного!"
          )
        end
        
        sleep(4) # Увеличиваем задержку
        
        # Объяснение задания
        safe_send(bot, message.chat.id) do
          bot.api.send_message(
            chat_id: message.chat.id,
            text: "Вы должны доказать что являетесь отличным магом и алхимиком. Для этого, создайте зелье превращения."
          )
        end
        
        sleep(4) # Увеличиваем задержку
        
        # Саркастическое замечание о Дамблдоре
        safe_send(bot, message.chat.id) do
          bot.api.send_message(
            chat_id: message.chat.id,
            text: "И как бы я не хотел, но Дамблдор приказал передавать вам эту инструкцию... но тогда зачем мне вас проверять? Впрочем неважно, вы и с этим не справитесь..."
          )
        end
        
        sleep(5) # Увеличиваем задержку
        
        # Секретное сообщение от "друга"
        safe_send(bot, message.chat.id) do
          bot.api.send_photo(
            chat_id: message.chat.id,
            photo: Faraday::UploadIO.new('message.jpg', 'image/jpg'),
            caption: "'Текст в сообщении'\nСеверус ещё не знает что ты будешь готовить сливочное пиво, но так будет веселее 😉"
          )
        end
        
        sleep(4) # Увеличиваем задержку
        
        # Инструкция по поиску ингредиентов
        safe_send(bot, message.chat.id) do
          bot.api.send_message(
            chat_id: message.chat.id,
            text: "Все ингридиенты ты найдешь в своем верхнем шкафу (где у тебя обычно лежат чипсы), в холодильнике и морозилке"
          )
        end
        
        sleep(4) # Увеличиваем задержку
        
        safe_send(bot, message.chat.id) do
          bot.api.send_message(
            chat_id: message.chat.id,
            text: "Обязательно возьми свою самую большую кружку!"
          )
        end
        
        sleep(3) # Увеличиваем задержку
        
        # Начинаем первый шаг приготовления
        user_progress[message.chat.id] = { current_step: 0 }
        send_brewing_step(bot, message.chat.id, 0)

      when '/help'
        safe_send(bot, message.chat.id) do
          bot.api.send_message(
            chat_id: message.chat.id,
            text: "Следуй инструкциям и нажимай 'Готово!' после выполнения каждого шага. И помни - Снейп всегда наблюдает..."
          )
        end
      end

    when Telegram::Bot::Types::CallbackQuery
      if message.data.start_with?('step_')
        handle_step_completion(bot, message, user_progress)
      end
    end
  end
end