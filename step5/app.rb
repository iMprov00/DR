require 'telegram/bot'

token = '8187306369:AAG4xc7doijuqcqNYfZBOWffkHuTng2Sl38'

# Метод для безопасной отправки с обработкой ошибок
def safe_send(bot, chat_id, &block)
  retries = 0
  max_retries = 3
  
  begin
    # Добавляем небольшую паузу перед каждым запросом
    sleep(1) if retries == 0
    
    block.call
  rescue Telegram::Bot::Exceptions::ResponseError => e
    if e.error_code == 429
      retry_after = if e.response && e.response['parameters']
                      e.response['parameters']['retry_after'] || 30
                    else
                      30
                    end
      puts "Превышен лимит запросов. Ждем #{retry_after} секунд..."
      sleep(retry_after)
      retries += 1
      retry if retries <= max_retries
    else
      puts "Ошибка Telegram API: #{e.message}"
      raise e
    end
  rescue StandardError => e
    puts "Произошла непредвиденная ошибка: #{e.message}"
    raise e
  end
end

# Основной код бота
Telegram::Bot::Client.run(token) do |bot|
  bot.listen do |message|
    case message
    when Telegram::Bot::Types::Message
      case message.text
      when '/start'
        # Приветственное сообщение от Гарри
        safe_send(bot, message.chat.id) do
        bot.api.send_animation(
          chat_id: message.chat.id,
          animation: Faraday::UploadIO.new('hello.gif', 'image/gif'))
        end

        safe_send(bot, message.chat.id) do
          bot.api.send_message(
            chat_id: message.chat.id,
            text: "Здравствуй, Стеша! ✨\n\nТы не представляешь, как я рад тебя видеть! Ты проявила невероятную храбрость и мудрость, справившись со всеми испытаниями. Ты настоящая героиня, которая смогла всех нас спасти!"
          )
        end

      
        sleep(4)
        
        # Поздравление с днем рождения
        safe_send(bot, message.chat.id) do
          bot.api.send_message(
            chat_id: message.chat.id,
            text: "От всего сердца хочу поздравить тебя с днём рождения! 🎉\n\nЖелаю тебе, чтобы твоя жизнь была наполнена таким же волшебством, какое ты приносишь всем вокруг. Пусть каждый твой день будет похож на страницу из самой удивительной сказки, полной чудес, приключений и счастливых моментов!"
          )
        end
        
        sleep(4)
        
        # Сообщение про артефакт
        safe_send(bot, message.chat.id) do
          bot.api.send_message(
            chat_id: message.chat.id,
            text: "Кстати... твоя магия была настолько сильной, что пробудила древние артефакты! 🔮\n\nЗаклинаю тебя заглянуть в диван - там должно было появиться нечто особенное, что ждало именно твоего прикосновения. Думаю, это тебе понравится..."
          )
        end
        
        sleep(4)
        
        # Прощальное сообщение
        safe_send(bot, message.chat.id) do
          bot.api.send_message(
            chat_id: message.chat.id,
            text: "Ещё раз с днём рождения, Стеша! 🥳\n\nПусть этот год принесёт тебе столько же радости, сколько ты приносишь другим. До встречи перед Новым годом!"
          )
        end

      when '/help'
        safe_send(bot, message.chat.id) do
          bot.api.send_message(
            chat_id: message.chat.id,
            text: "Просто напиши /start чтобы получить поздравление от Гарри Поттера! 🪄"
          )
        end
      end
    end
  end
end