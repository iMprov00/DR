require 'telegram/bot'

token = '8275366314:AAFh97u2XTHIw2OVKlOpyrS-NN4NflPVFls'

# Хэш для хранения состояний пользователей
user_states = {}

Telegram::Bot::Client.run(token) do |bot|
  bot.listen do |message|
    case message
    when Telegram::Bot::Types::Message
      case message.text
      when '/start'
        # Отправляем гифку hello.gif
        bot.api.send_animation(
          chat_id: message.chat.id,
          animation: Faraday::UploadIO.new('hello.gif', 'image/gif')
        )
        
        sleep(1)
        
        # Отправляем первое сообщение
        bot.api.send_message(chat_id: message.chat.id, text: "Стеша! Наконец-то! С Днём Рождения! У меня тут для тебя сюрпризик припрятан...")
        
        sleep(4)

        # Отправляем картинку tort.png
        bot.api.send_photo(
          chat_id: message.chat.id,
          photo: Faraday::UploadIO.new('tort.jpg', 'image/jpg')
        )
        
        sleep(2)


        # Отправляем первое сообщение
        bot.api.send_message(chat_id: message.chat.id, text: "Ой, кажется этот торт был для Гарри... Ну мы ему ничего не скажем, правда?")
        
        sleep(4)

        # Сообщение и кнопка отправляются вместе
        buttons = [[Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Прочитать письмо', callback_data: 'read_letter')]]
        markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: buttons)
        bot.api.send_message(
          chat_id: message.chat.id,
          text: 'Извини, я не могу долго разговаривать. Дела в Хогвардсе очень серьёзные... Мне кое-кто передал для тебя это письмо, велел никому не показывать. Прочти, да побыстрее!',
          reply_markup: markup
        )
        
        # Сбрасываем состояние пользователя
        user_states[message.chat.id] = nil

      when '/help'
        bot.api.send_message(chat_id: message.chat.id, text: "Вспомни, какое животное на гербе Гриффиндора!")
      
      else
        # Проверяем, ожидаем ли мы ответ от этого пользователя
        if user_states[message.chat.id] == 'waiting_for_answer'
          user_answer = message.text.downcase.strip
          
          if ['лев', 'Лев'].include?(user_answer)
            # Правильный ответ
            bot.api.send_message(chat_id: message.chat.id, text: "Правильно! На гербе изображен лев! 🦁🎉")
            bot.api.send_photo(
              chat_id: message.chat.id,
              photo: Faraday::UploadIO.new('gerb.jpg', 'image/jpg')
            )
            bot.api.send_animation(
              chat_id: message.chat.id,
              animation: Faraday::UploadIO.new('go.gif', 'image/gif')
            )
            bot.api.send_message(chat_id: message.chat.id, text: "Я бы никогда не догадался! Кажется ты смогла узнать куда идти дальше, похоже тебя ждем Римус! Если будут проблемы при общении через магическую скрижаль, то сообщи ему @iMprovFL\nПошли скорей! @remus_dr_bot")
            # Сбрасываем состояние
            user_states[message.chat.id] = nil
          else
            # Неправильный ответ
            bot.api.send_message(chat_id: message.chat.id, text: "Неправильно! Посмотри внимательнее на герб Гриффиндора и попробуй ещё раз.")
          end
        end
      end

    when Telegram::Bot::Types::CallbackQuery
      # Обработка нажатия на кнопку
      if message.data == 'read_letter'
        # Отправляем текст письма
        bot.api.send_animation(
          chat_id: message.from.id,
          animation: Faraday::UploadIO.new('message.gif', 'image/gif')
        )

        bot.api.send_message(
          chat_id: message.from.id, 
          text: "'Стефания. Чтобы понять, куда смотреть дальше, вспомни кто изображен на гербе Гриффиндора.'"
        )
        
        # Устанавливаем состояние "ожидание ответа" для этого пользователя
        user_states[message.from.id] = 'waiting_for_answer'
        
        # Отправляем подсказку
        bot.api.send_message(
          chat_id: message.from.id,
          text: "Напиши ответ:"
        )
        
        # Ответ на callback, чтобы убрать "часики" на кнопке
        bot.api.answer_callback_query(callback_query_id: message.id)
      end
    end
  end
end