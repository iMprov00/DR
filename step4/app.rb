require 'telegram/bot'

token = '7901441008:AAGyZ3pDHtMv7H8OKWUeHbJnkhv8RMBD7Cg'

# Хэш для хранения прогресса пользователей
user_progress = {}

# Улучшенный метод для безопасной отправки с обработкой ошибок
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
    elsif e.error_code == 400
      if e.message.include?('query is too old') || e.message.include?('response timeout expired') || e.message.include?('query ID is invalid')
        puts "Игнорируем устаревший запрос: #{e.message}"
        return # Просто игнорируем устаревшие запросы
      else
        raise e
      end
    else
      raise e
    end
  rescue => e
    puts "Ошибка при отправке: #{e.message}"
    sleep(2)
    retries += 1
    retry if retries <= 2
  end
end

# Метод для отправки с задержкой
def send_with_delay(bot, chat_id, delay = 3, &block)
  sleep(delay)
  safe_send(bot, chat_id, &block)
end

# Основной код бота
Telegram::Bot::Client.run(token) do |bot|
  bot.listen do |message|
    case message
    when Telegram::Bot::Types::Message
      case message.text
      when '/start'
        # Приветствие от взволнованного Дамблдора
        safe_send(bot, message.chat.id) do
          bot.api.send_animation(
            chat_id: message.chat.id,
            animation: Faraday::UploadIO.new('dumbledore_worried.gif', 'image/gif')
          )
        end

        send_with_delay(bot, message.chat.id, 5) do
          bot.api.send_message(
            chat_id: message.chat.id,
            text: "Стеша... наконец-то ты здесь! *взволнованно поправляет очки* Ты прошла этот долгий путь..."
          )
        end
        
        send_with_delay(bot, message.chat.id, 6) do
          bot.api.send_message(
            chat_id: message.chat.id,
            text: "Прости за все эти загадки и испытания... но иначе я не мог. Иначе *Он* бы сразу нашел тебя... Тот, чьё имя нельзя произносить..."
          )
        end
        
        send_with_delay(bot, message.chat.id, 7) do
          bot.api.send_message(
            chat_id: message.chat.id,
            text: "В Хогвартсе происходит нечто ужасное... темные силы проникли в школу... мы не можем терять ни секунды!"
          )
        end
        
        send_with_delay(bot, message.chat.id, 6) do
          bot.api.send_message(
            chat_id: message.chat.id,
            text: "Только ты, с твоей огромной душой, добрым и чутким сердцем можешь спасти нас всех..."
          )
        end
        
        send_with_delay(bot, message.chat.id, 6) do
          bot.api.send_message(
            chat_id: message.chat.id,
            text: "Тебе нужно вернуться в прошлое и произнести особое заклинание. Для этого я оставил тебе палочку и Маховик Времени в твоем шкафу на кухне, где ты хранишь лекарства."
          )
        end
        
        send_with_delay(bot, message.chat.id, 7) do
          # Кнопка "Готово" для первого этапа
          buttons = [[Telegram::Bot::Types::InlineKeyboardButton.new(
            text: 'Готово',
            callback_data: "items_found"
          )]]
          
          markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: buttons)
          
          bot.api.send_message(
            chat_id: message.chat.id,
            text: "Дай знать, когда найдешь палочку и Маховик Времени...",
            reply_markup: markup
          )
        end

        user_progress[message.chat.id] = { stage: 'waiting_for_items' }

      when '/help'
        safe_send(bot, message.chat.id) do
          bot.api.send_message(
            chat_id: message.chat.id,
            text: "Следуй указаниям профессора Дамблдора. Нажимай кнопки, когда будешь готова продолжить."
          )
        end
      else
        # Обработка ввода заклинания
        if user_progress[message.chat.id] && user_progress[message.chat.id][:stage] == 'waiting_for_spell'
          safe_send(bot, message.chat.id) do
            bot.api.send_message(
              chat_id: message.chat.id,
              text: "Дорогая наша Стеша, ты смогла, ты справилась... Твоя магия любви настолько сильна, что ты разрушила все злые чары! Ты спасла Хогвартс, спасла людей, спасла себя и своих близких! 🌟"
            )
          end
          
          send_with_delay(bot, message.chat.id, 6) do
            bot.api.send_animation(
              chat_id: message.chat.id,
              animation: Faraday::UploadIO.new('hogwarts_saved.gif', 'image/gif')
            )
          end
          
          send_with_delay(bot, message.chat.id, 6) do
            bot.api.send_message(
              chat_id: message.chat.id,
              text: "Кажется, кто-то к тебе пришел... Иди поздоровайся!",
              parse_mode: 'Markdown'
            )
          end
          
          # Очищаем прогресс
          user_progress.delete(message.chat.id)
        end
      end

    when Telegram::Bot::Types::CallbackQuery
      # Обрабатываем callback_query с защитой от устаревших запросов
      begin
        case message.data
        when 'items_found'
          # Подтверждаем нажатие кнопки как можно быстрее
          safe_send(bot, message.from.id) do
            bot.api.answer_callback_query(callback_query_id: message.id, text: "Прекрасно! ✨")
          end
          
          chat_id = message.from.id
          
          send_with_delay(bot, chat_id, 4) do
            bot.api.send_message(
              chat_id: chat_id,
              text: "Теперь воспользуйся Маховиком Времени... мы должны перенестись назад, в прошлое."
            )
          end
          
          send_with_delay(bot, chat_id, 5) do
            # Кнопка "Покрутить" для активации Вихря Времени
            buttons = [[Telegram::Bot::Types::InlineKeyboardButton.new(
              text: 'Покрутить Маховик Времени',
              callback_data: "time_turn"
            )]]
            
            markup = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: buttons)
            
            bot.api.send_message(
              chat_id: chat_id,
              text: "Когда будешь готова...",
              reply_markup: markup
            )
          end
          
          user_progress[chat_id] = { stage: 'waiting_for_time_turn' }

        when 'time_turn'
          # Подтверждаем нажатие кнопки как можно быстрее
          safe_send(bot, message.from.id) do
            bot.api.answer_callback_query(callback_query_id: message.id, text: "Маховик запущен! ⏳")
          end
          
          chat_id = message.from.id
          
          send_with_delay(bot, chat_id, 3) do
            bot.api.send_animation(
              chat_id: chat_id,
              animation: Faraday::UploadIO.new('time_turner.gif', 'image/gif')
            )
          end
          
          send_with_delay(bot, chat_id, 6) do
            bot.api.send_message(
              chat_id: chat_id,
              text: "Ты видишь прошлое... видишь себя маленькую... Видишь, как ты росла и взрослела, как мечтала и шла к своим целям..."
            )
          end
          
          send_with_delay(bot, chat_id, 7) do
            bot.api.send_message(
              chat_id: chat_id,
              text: "Видишь, как много училась и трудилась... Как проходила этот большой жизненный путь... Как много хороших людей окружало и оберегало тебя все это время..."
            )
          end
          
          send_with_delay(bot, chat_id, 7) do
            bot.api.send_message(
              chat_id: chat_id,
              text: "И вот теперь ты стоишь тут, на перепутье своего возраста, в момент, когда время и реальность переплетаются, когда уровень магии превышает все высоты, и волшебство появляется там, где ты его не ждешь..."
            )
          end
          
          send_with_delay(bot, chat_id, 7) do
            bot.api.send_message(
              chat_id: chat_id,
              text: "Именно здесь ты можешь изменить себя, изменить мир, изменить реальность... Сделать её лучше, сделать лучше себя и других..."
            )
          end
          
          send_with_delay(bot, chat_id, 6) do
            bot.api.send_message(
              chat_id: chat_id,
              text: "Вспомни прошлое... посмотри на настоящее... подумай о будущем..."
            )
          end
          
          send_with_delay(bot, chat_id, 5) do
            bot.api.send_message(
              chat_id: chat_id,
              text: "Вспомни людей, которые были рядом и которые рядом сейчас... Подумай о том, как тебя любят и ценят..."
            )
          end
          
          send_with_delay(bot, chat_id, 6) do
            bot.api.send_message(
              chat_id: chat_id,
              text: "Подумай о любви, которой полно твое сердце... Вспомни все самое прекрасное из своей жизни..."
            )
          end
          
          send_with_delay(bot, chat_id, 6) do
            bot.api.send_message(
              chat_id: chat_id,
              text: "И произнеси лишь одно слово, которое ты видишь перед глазами... оно и будет заклинанием...\n\n*Напиши заклинание:*",
              parse_mode: 'Markdown'
            )
          end
          
          user_progress[chat_id] = { stage: 'waiting_for_spell' }
        end
      rescue Telegram::Bot::Exceptions::ResponseError => e
        if e.error_code == 400 && (e.message.include?('query is too old') || e.message.include?('query ID is invalid'))
          puts "Игнорируем устаревший callback: #{e.message}"
        else
          raise e
        end
      end
    end
  end
end