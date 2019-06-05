package volkova.restful.digest.entity.enum

import com.fasterxml.jackson.annotation.JsonValue


import javax.persistence.AttributeConverter
import javax.persistence.Converter


enum class PublicationType(@get:JsonValue val value: String) {

    ARTICLE("Стаття");

    companion object {

        @Converter
        class EnumConverter : AttributeConverter<PublicationType, String> {

            override fun convertToDatabaseColumn(attribute: PublicationType?) =
                    attribute?.value ?: ARTICLE.value

            override fun convertToEntityAttribute(dbData: String?): PublicationType {
                PublicationType.values().forEach { if (it.value == dbData) return it }
                return ARTICLE
            }

        }

    }

}